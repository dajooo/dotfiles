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
def prompt_yes_no_all [question: string, answer_all: bool] {
    if $answer_all {
        return {
            confirmed: true
            answer_all: true
        }
    }

    loop {
        print -n $"($question) [y/N/all] "
        let input = (input)
        match $input {
            "y" | "Y" => { 
                return {
                    confirmed: true
                    answer_all: false
                }
            }
            "n" | "N" | "" => { 
                return {
                    confirmed: false
                    answer_all: false
                }
            }
            "a" | "A" | "all" => {
                return {
                    confirmed: true
                    answer_all: true
                }
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
def create_symlink [source: string, target: string, answer_all: bool] {
    let expanded_target = (expand_path $target)
    ensure_parent_dir $expanded_target
    
    # Check if target already exists
    if ($expanded_target | path exists) {
        let prompt = $"($expanded_target) already exists. Replace it?"
        let result = (prompt_yes_no_all $prompt $answer_all)
        if not $result.confirmed {
            print $"Skipped: ($expanded_target)"
            return $result.answer_all
        }
        rm -rf $expanded_target
        return $result.answer_all
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
    
    return $answer_all
}

# Process each mapping
def process_mapping [mapping, answer_all: bool] {
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
        create_symlink $source $target $answer_all
    } else {
        $answer_all
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
    
    let config = load_config
    let answer_all = false
    $config.pathMappings | reduce -f $answer_all { |mapping, acc|
        process_mapping $mapping $acc
    }
    print "✨ Configuration applied successfully!"
}

# Run the main function
main
