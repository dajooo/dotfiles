#!/bin/bash

# Bash prompt library
# Usage: source this file and use prompt_yes_no "Your question?"

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
