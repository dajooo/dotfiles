# Load and parse the dotfiles configuration
def load_config [] {
    open dotfiles.json
}

# Convert ~ to home directory
def expand_path [path: string] {
    let home = if $nu.os-info.name == "windows" {
        $env.USERPROFILE
    } else {
        $env.HOME
    }
    $path | str replace "~" $home
}

# Create parent directory if it doesn't exist
def ensure_parent_dir [path: string] {
    let parent = ($path | path dirname)
    if not ($parent | path exists) {
        mkdir $parent
    }
}

# Prompt for yes/no/all
def prompt_yes_no_all [question: string] {
    if $env.ALL_YES? == true {
        return true
    }

    loop {
        print -n $"($question) [y/N/all] "
        let input = (input)
        match $input {
            "y" | "Y" => { return true }
            "n" | "N" | "" => { return false }
            "a" | "A" | "all" => {
                $env.ALL_YES = true
                return true
            }
            _ => { print "Please answer yes, no, or all." }
        }
    }
}

# Prompt for yes/no
def prompt_yes_no [question: string] {
    loop {
        print -n $"($question) [y/N] "
        let input = (input)
        match $input {
            "y" | "Y" => { return true }
            "n" | "N" | "" => { return false }
            _ => { print "Please answer yes or no." }
        }
    }
}

# Create symlink based on source type
def create_symlink [source: string, target: string] {
    let expanded_target = (expand_path $target)
    ensure_parent_dir $expanded_target
    
    # Check if target already exists
    if ($expanded_target | path exists) {
        let prompt = $"($expanded_target) already exists. Replace it?"
        if not (prompt_yes_no_all $prompt) {
            print $"Skipped: ($expanded_target)"
            return
        }
        rm -rf $expanded_target
    }

    # Check if source is a directory
    let is_dir = ($source | path type) == "dir"

    # Create the symlink
    print $"Creating symlink: ($source) -> ($expanded_target)"
    if $nu.os-info.name == "windows" {
        if $is_dir {
            ^cmd /c mklink /D $expanded_target $source
        } else {
            ^cmd /c mklink $expanded_target $source
        }
    } else {
        ln -s $source $expanded_target
    }
}

# Process each mapping
def process_mapping [mapping] {
    let source = ("files/" + $mapping.path | path expand)
    let target = $mapping.diskPath
    let os = if ($mapping | get -i os) == null { "all" } else { $mapping.os }
    
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
    
    if $should_apply {
        create_symlink $source $target
    }
}

# Main execution
def main [] {
    print "🔗 Creating symlinks..."
    
    # Ask for confirmation before proceeding
    if not (prompt_yes_no "Would you like to proceed with creating symlinks?") {
        print "Operation cancelled."
        exit 0
    }

    # Initialize ALL_YES flag
    $env.ALL_YES = false
    
    let config = load_config
    $config.pathMappings | each { |mapping|
        process_mapping $mapping
    }
    print "✨ Configuration applied successfully!"
}

# Run the main function
main
