# Load and parse the dotfiles configuration
def load_config [] {
    open dotfiles.json
}

# Convert ~ to home directory and normalize path separators
def expand_path [path: string] {
    let home = if $nu.os-info.name == "windows" {
        $env.USERPROFILE
    } else {
        $env.HOME
    }
    let expanded = ($path | str replace "~" $home)
    if $nu.os-info.name == "windows" {
        $expanded | str replace -a "/" "\\"
    } else {
        $expanded
    }
}

# Create parent directory if it doesn't exist
def ensure_parent_dir [path: string] {
    let parent = ($path | path dirname)
    if not ($parent | path exists) {
        mkdir $parent
    }
}

# ANSI color codes
def get_colors [] {
    {
        red: (ansi red)
        green: (ansi green)
        yellow: (ansi yellow)
        reset: (ansi reset)
        bold: (ansi -e '1')
    }
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

    # Create the symlink
    print_info $"Creating symlink: ($source) -> ($expanded_target)"
    if $nu.os-info.name == "windows" {
        # Get absolute paths
        let abs_source = ($source | path expand)
        let abs_target = ($expanded_target | path expand)
        
        # Ensure paths use backslashes
        let win_source = ($abs_source | str replace -a "/" "\\")
        let win_target = ($abs_target | str replace -a "/" "\\")
        
    # Log detailed information before creating the symlink
    print_info $"Creating symlink: source='$source', target='$expanded_target', is_dir=$is_dir"
    
    # Create the symlink using mklink
    if $is_dir {
        let result = ^cmd /c mklink /D $win_target $win_source
        print_info $"mklink /D result: $result"
    } else {
        let result = ^cmd /c mklink $win_target $win_source
        print_info $"mklink result: $result"
    }
    } else {
        # Get absolute paths
        let abs_source = ($source | path expand)
        let abs_target = ($expanded_target | path expand)
        
        # Create the symlink
        if $is_dir {
            # For directories, use -s only (no -f to prevent issues with existing directories)
            ^ln -s $abs_source $abs_target
        } else {
            # For files, use -sf to force creation
            ^ln -sf $abs_source $abs_target
        }
    }
    
    return $answer_all
}

# Process each mapping
def process_mapping [mapping, answer_all: bool] {
    let source = ($mapping.path)
    let target = $mapping.diskPath
    let os = if ($mapping | get -i os) == null { "all" } else { $mapping.os }
    
    # Check if mapping should be applied for current OS
    let should_apply = if $os == "all" {
        true
    } else if $os == "windows" and $nu.os-info.name == "windows" {
        true
    } else if $os == "unix" and $nu.os-info.name != "windows" {
        true
    } else {
        false
    }
    
    if $should_apply {
        create_symlink $source $target $answer_all
    } else {
        $answer_all
    }
}

# Main execution
def main [
    --auto-yes(-y) # Auto-yes flag for non-interactive mode
] {
    # Check for auto-yes flag or environment variable
    let auto_yes = $auto_yes or (try { $env.DOTFILES_AUTO_YES == "true" } catch { false })
    print_info "🔗 Creating symlinks..."
    
    # Check for admin privileges on Windows
    if $nu.os-info.name == "windows" and (not (is-admin)) {
        print_error "Administrator privileges are required to create symlinks on Windows."
        print_info "Please run this script as Administrator:"
        print_info "1. Right-click on Windows Terminal"
        print_info "2. Select 'Run as administrator'"
        print_info "3. Navigate to this directory"
        print_info "4. Run the script again"
        exit 1
    }
    
    # Ask for confirmation before proceeding (unless auto-yes is set)
    if not $auto_yes and not (prompt_yes_no "Would you like to proceed with creating symlinks?") {
        print_error "Operation cancelled."
        exit 0
    }
    
    let config = load_config
    let answer_all = $auto_yes
    $config.pathMappings | reduce -f $answer_all { |mapping, acc|
        process_mapping $mapping $acc
    }
    print_success "✨ Configuration applied successfully!"
}

# Run the main function
if (try { $env.DOTFILES_AUTO_YES == "true" } catch { false }) {
    main --auto-yes
} else {
    main
}
