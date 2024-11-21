# Nushell Config File

# Disable welcome message
$env.config = {
    show_banner: false
}

# Default env values
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Starship configuration
$env.STARSHIP_SHELL = "nu"
$env.STARSHIP_CONFIG = if $nu.os-info.name == "windows" {
    $"($env.APPDATA)/starship.toml"
} else {
    $"($env.HOME)/.config/starship.toml"
}

# Set up the prompt
$env.PROMPT_COMMAND = { || 
    # Create starship cache directory if it doesn't exist
    let cache_dir = if $nu.os-info.name == "windows" {
        $"($env.APPDATA)/starship/cache"
    } else {
        $"($env.HOME)/.cache/starship"
    }
    if not ($cache_dir | path exists) {
        mkdir $cache_dir
    }
    
    # Initialize starship
    starship prompt
}

$env.PROMPT_COMMAND_RIGHT = { || "" }

# Aliases
alias ll = ls -l
alias la = ls -a
alias lla = ls -la
alias g = git
alias gst = git status
alias ga = git add
alias gc = git commit
alias gp = git push
alias gpl = git pull
alias gd = git diff
alias gco = git checkout

# Directory navigation
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# Git helpers
def git_branch [] {
    git branch | lines | str trim | where $it starts-with '*' | str replace '\* ' ''
}

def git_status_short [] {
    git status -s
}

# Development helpers
def mkcd [dirname: string] {
    mkdir $dirname
    cd $dirname
}

# Load environment config
source env.nu
