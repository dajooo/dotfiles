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

# Load environment setup
source env.nu

# Set up prompt using starship
source starship.nu

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
