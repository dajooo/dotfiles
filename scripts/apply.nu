# Load and parse the dotfiles configuration
def load_config [] {
    open dotfiles.json
}

# Check if running with admin privileges on Windows
def is_admin [] {
    if $nu.os-info.name == "windows" {
        let result = (do { ^net session } | complete)
        $result.exit_code == 0
    } else {
        # On Unix, we'll check if effective user ID is 0 (root)
        (sys).uid == 0
    }
}

# Convert ~ to home directory and normalize path separators
def expand_path [path: string] {
    let home = if $nu.os-info.name == "windows" {
        $env.USERPROFILE
    } else {
        $env.HOME
    }
    let expanded = ($path | str replace "~" $home)
    # Convert forward slashes to backslashes on Windows
    let normalized = if $nu.os-info.name == "windows" {
        $expanded | str replace "/" "\\"
    } else {
        $expanded
    }
    print_debug $"Expanding path: ($path) -> ($normalized)"
    $normalized
}

# Create parent directory if it doesn't exist
def ensure_parent_dir [path: string] {
    let parent = ($path | path dirname)
    if not ($parent | path exists) {
        print_debug $"Creating parent directory: ($parent)"
        mkdir $parent
    }
}

# ANSI color codes
def get_colors [] {
    {
        red: (ansi red)
        green: (ansi green)
        yellow: (ansi yellow)
        blue: (ansi blue)
        reset: (ansi reset)
        bold: (ansi -e '1')
    }
}

# Print debug message
def print_debug [message: string] {
    let colors = get_colors
    print $"($colors.blue)DEBUG: ($message)($colors.reset)"
}

# Prompt for yes/no/all with consistent formatting
def prompt_yes_no_all [question: string, answer_all: bool] {
    if $answer_all {
        return {
            confirmed: true
            answer_all: true
        }
    }

    let colors = get_colors
    
    loop {
        # Format: Question [y/N/all]
        print -n $"($colors.bold)($question)($colors.reset) ($colors.yellow)[y/N/all]($colors.reset) "
        
        let input = (input)
        let lower_input = ($input | str downcase)
        
        match $lower_input {
            "y" | "yes" => { 
                return {
                    confirmed: true
                    answer_all: false
                }
            }
            "n" | "no" | "" => { 
                return {
                    confirmed: false
                    answer_all: false
                }
            }
            "a" | "all" => {
                return {
                    confirmed: true
                    answer_all: true
                }
            }
            _ => { 
                print $"($colors.red)Please answer yes, no, or all.($colors.reset)"
            }
        }
    }
}

# Prompt for yes/no with consistent formatting
def prompt_yes_no [question: string] {
    let colors = get_colors
    
    loop {
        # Format: Question [y/N]
        print -n $"($colors.bold)($question)($colors.reset) ($colors.yellow)[y/N]($colors.reset) "
        
        let input = (input)
        let lower_input = ($input | str downcase)
        
        match $lower_input {
            "y" | "yes" => { return true }
            "n" | "no" | "" => { return false }
            _ => { 
                print $"($colors.red)Please answer yes or no.($colors.reset)"
            }
        }
    }
}

# Print error message
def print_error [message: string] {
    let colors = get_colors
    print $"($colors.red)Error: ($message)($colors.reset)"
}

# Print success message
def print_success [message: string] {
    let colors = get_colors
    print $"($colors.green)($message)($colors.reset)"
}

# Print info message
def print_info [message: string] {
    let colors = get_colors
    print $"($colors.yellow)($message)($colors.reset)"
}

# Create symlink based on source type
def create_symlink [source: string, target: string, answer_all: bool] {
    let expanded_target = (expand_path $target)
    ensure_parent_dir $expanded_target
    
    # Check if target already exists
    if ($expanded_target | path exists) {
        let prompt = $"($expanded_target) already exists. Replace it?"
        let result = (prompt_yes_no_all $prompt $answer_all)
        if not $result.confirmed {
            print_info $"Skipped: ($expanded_target)"
            return $result.answer_all
        }
        rm -rf $expanded_target
        return $result.answer_all
    }

    # Check if source is a directory
    let is_dir = ($source | path type) == "dir"
    print_debug $"Source type check: ($source) is directory? ($is_dir)"

    # Create the symlink
    print_info $"Creating symlink: ($source) -> ($expanded_target)"
    if $nu.os-info.name == "windows" {
        # Ensure paths use backslashes and are properly quoted
        let win_source = ($source | str replace "/" "\\")
        let win_target = ($expanded_target | str replace "/" "\\")
        if $is_dir {
            print_debug "Using Windows directory symlink command"
            ^cmd /c mklink /D $win_target $win_source
        } else {
            print_debug "Using Windows file symlink command"
            ^cmd /c mklink $win_target $win_source
        }
    } else {
        print_debug "Using Unix symlink command"
        ln -s $source $expanded_target
    }
    
    return $answer_all
}

# Process each mapping
def process_mapping [mapping, answer_all: bool] {
    # Fix the double "files" in the path by using path relative to current directory
    let source = ($mapping.path | path expand)
    let target = $mapping.diskPath
    let os = if ($mapping | get -i os) == null { "all" } else { $mapping.os }
    
    print_debug $"Processing mapping:"
    print_debug $"- Source: ($source)"
    print_debug $"- Target: ($target)"
    print_debug $"- OS: ($os)"
    print_debug $"- Current OS: ($nu.os-info.name)"
    
    # Check if mapping should be applied for current OS
    let should_apply = if $os == "all" {
        true
    } else if $os == "windows" {
        $nu.os-info.name == "windows"
    } else if $os == "unix" {
        $nu.os-info.name != "windows"
    } else {
        false
    }
    
    print_debug $"Should apply? ($should_apply)"
    
    if $should_apply {
        create_symlink $source $target $answer_all
    } else {
        $answer_all
    }
}

# Main execution
def main [] {
    print_info "🔗 Creating symlinks..."
    
    # Check for admin privileges on Windows
    if $nu.os-info.name == "windows" and (not (is_admin)) {
        print_error "Administrator privileges are required to create symlinks on Windows."
        print_info "Please run this script as Administrator:"
        print_info "1. Right-click on Windows Terminal"
        print_info "2. Select 'Run as administrator'"
        print_info "3. Navigate to this directory"
        print_info "4. Run the script again"
        exit 1
    }
    
    # Print system information
    print_debug $"System Information:"
    print_debug $"- OS: ($nu.os-info.name)"
    if $nu.os-info.name == "windows" {
        print_debug $"- Home directory: ($env.USERPROFILE)"
    } else {
        print_debug $"- Home directory: ($env.HOME)"
    }
    
    # Ask for confirmation before proceeding
    if not (prompt_yes_no "Would you like to proceed with creating symlinks?") {
        print_error "Operation cancelled."
        exit 0
    }
    
    let config = load_config
    let answer_all = false
    $config.pathMappings | reduce -f $answer_all { |mapping, acc|
        process_mapping $mapping $acc
    }
    print_success "✨ Configuration applied successfully!"
}

# Run the main function
main
