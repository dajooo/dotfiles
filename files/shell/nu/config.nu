# Nushell Config File

# Disable welcome message
$env.config = {
    show_banner: false
    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }
}

source scripts.nu
source aliases.nu

# Load environment setup
source env.nu

# Set up prompt using starship
source starship.nu

# Set up zoxide
source zoxide.nu

# Aliases
alias ll = ls -l
alias la = ls -a
alias lla = ls -la

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