#!/bin/bash

# One-click installer for dotfiles
DOTFILES_DIR="$HOME/.dotfiles"

# Parse command line arguments
AUTO_YES=false
while getopts "y" opt; do
  case $opt in
    y) AUTO_YES=true ;;
    *) ;;
  esac
done

# Embedded prompt library
# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to check if we're in an interactive terminal
is_interactive() {
    # Check if we have a terminal and if stdin is a terminal
    if [ -t 0 ] && [ -t 1 ]; then
        return 0
    else
        return 1
    fi
}

# Function to display a styled prompt
# Returns 0 for yes, 1 for no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"  # Default to 'n' if not specified
    
    # If -y flag is set, automatically return true
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    
    # If not interactive, use default
    if ! is_interactive; then
        [ "$default" = "y" ] && return 0 || return 1
    fi
    
    local yn
    
    # Format the prompt with colors and styling
    printf "${BOLD}${prompt}${NC} "
    
    # Show appropriate default
    if [ "$default" = "y" ]; then
        printf "${GREEN}[Y/n]${NC} "
    else
        printf "${YELLOW}[y/N]${NC} "
    fi
    
    # Read the answer
    read -r yn
    
    # Convert to lowercase
    yn=${yn,,}
    
    # Handle empty input according to default
    if [ -z "$yn" ]; then
        yn=$default
    fi
    
    # Process the response
    case "$yn" in
        y|yes)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to display error message
prompt_error() {
    printf "${RED}Error: %s${NC}\n" "$1" >&2
}

# Function to display success message
prompt_success() {
    printf "${GREEN}%s${NC}\n" "$1"
}

# Function to display info message
prompt_info() {
    printf "${YELLOW}%s${NC}\n" "$1"
}

echo "🚀 Welcome to dotfiles installer!"

# Check and install dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Check for wget
    if ! command -v wget &> /dev/null; then
        missing_deps+=("wget")
    fi
    
    # Check for sudo
    if ! command -v sudo &> /dev/null; then
        prompt_error "sudo is not available. Please install sudo and ensure you have appropriate permissions."
        exit 1
    fi

    # Install missing dependencies if any
    if [ ${#missing_deps[@]} -ne 0 ]; then
        prompt_info "The following dependencies are missing: ${missing_deps[*]}"
        if prompt_yes_no "Would you like to install them?" "y"; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y "${missing_deps[@]}"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "${missing_deps[@]}"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm "${missing_deps[@]}"
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y "${missing_deps[@]}"
            elif command -v apk &> /dev/null; then
                sudo apk add "${missing_deps[@]}"
            else
                prompt_error "Could not determine package manager. Please install: ${missing_deps[*]}"
                exit 1
            fi
        else
            prompt_error "Dependencies are required for installation. Exiting."
            exit 1
        fi
    fi
}

# Show installation plan
prompt_info "This script will:"
echo "1. Install required dependencies (git, curl, wget) if missing"
echo "2. Clone dotfiles repository to $DOTFILES_DIR"
echo "3. Initialize and update git submodules"
echo "4. Install nushell and starship"
echo "5. Set up shell configuration"

# Ask for confirmation before proceeding
if ! prompt_yes_no "Would you like to proceed with the installation?" "y"; then
    prompt_info "Installation cancelled."
    exit 0
fi

# Check and install dependencies
prompt_info "🔍 Checking dependencies..."
check_dependencies

# Clone repository if it doesn't exist
if [ ! -d "$DOTFILES_DIR" ]; then
    prompt_info "📦 Cloning repository..."
    git clone https://github.com/dajooo/dotfiles.git "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    prompt_info "📥 Initializing submodules..."
    git submodule update --init --recursive
else
    prompt_info "📂 Repository already exists."
    if prompt_yes_no "Would you like to update it?" "y"; then
        cd "$DOTFILES_DIR"
        
        # Initialize variables
        SKIP_UPDATE=
        STASHED=
        
        # Check for local changes
        if [ -n "$(git status --porcelain)" ]; then
            prompt_info "Local changes detected in the repository."
            
            # Present options
            echo "How would you like to handle local changes?"
            echo "1) Stash changes and reapply after update"
            echo "2) Discard local changes"
            echo "3) Skip update to preserve changes (default)"
            
            # Default to option 3 (skip) if -y flag is set
            if [ "$AUTO_YES" = true ]; then
                CHOICE=3
            else
                read -p "Enter choice [1-3]: " CHOICE
                # Default to 3 if empty
                CHOICE=${CHOICE:-3}
            fi
            
            case $CHOICE in
                1)
                    prompt_info "Stashing local changes..."
                    git stash
                    STASHED=true
                    ;;
                2)
                    prompt_info "Discarding local changes..."
                    git reset --hard
                    ;;
                3|*)
                    prompt_info "Skipping repository update to preserve your local changes."
                    SKIP_UPDATE=true
                    ;;
            esac
        fi
        
        if [ -z "$SKIP_UPDATE" ]; then
            prompt_info "Updating repository..."
            git pull || {
                prompt_error "Failed to update repository. Please resolve conflicts manually."
                exit 1
            }
            prompt_info "📥 Updating submodules..."
            git submodule update --init --recursive
            
            # Apply stashed changes if needed
            if [ "$STASHED" = true ]; then
                prompt_info "Reapplying stashed changes..."
                git stash pop
            fi
        fi
    fi
fi

# Change to dotfiles directory if not already there
cd "$DOTFILES_DIR"

# Make scripts executable
chmod +x scripts/nu/install-nu.sh
chmod +x scripts/apply.sh

# Run installation
prompt_info "⚙️ Installing nushell..."
./scripts/nu/install-nu.sh

prompt_info "🔧 Applying configuration..."
# Set environment variable for auto-yes if -y flag is set
if [ "$AUTO_YES" = true ]; then
    export DOTFILES_AUTO_YES="true"
else
    export DOTFILES_AUTO_YES="false"
fi
nu ./scripts/apply.nu

prompt_success "✨ Installation complete!"
echo "You can now:"
echo "1. Run 'exec nu' to switch to nushell immediately"
echo "2. Log out and log back in to use nushell as your default shell (if selected)"
echo "3. Run 'nu' to try nushell without making it default"
