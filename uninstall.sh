#!/bin/bash
SCRIPT_DIR="$(dirname "$0")"

# Function to prompt for yes/no
prompt_yes_no() {
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to prompt for yes/no/all
prompt_yes_no_all() {
    local path="$1"
    if [ "$ALL_YES" = true ]; then
        return 0
    fi
    while true; do
        read -p "Remove symlink for $path? [y/N/all] " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            [Aa]* ) ALL_YES=true; return 0;;
            * ) echo "Please answer yes, no, or all.";;
        esac
    done
}

echo "🧹 Unapplying dotfiles configuration..."

# Ask for confirmation before proceeding
if ! prompt_yes_no "Would you like to proceed with uninstallation?"; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Initialize ALL_YES flag
ALL_YES=false

# Load and parse dotfiles configuration
CONFIG_FILE="dotfiles.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to expand path
expand_path() {
    echo "$1" | sed "s|~|$HOME|g"
}

# Remove symlinks based on configuration
echo "Removing symlinks..."
while IFS= read -r line; do
    if [[ $line =~ \"diskPath\":\ *\"([^\"]+)\" ]]; then
        path="${BASH_REMATCH[1]}"
        expanded_path=$(expand_path "$path")
        
        # Check if path exists and is a symlink
        if [ -L "$expanded_path" ]; then
            if prompt_yes_no_all "$expanded_path"; then
                rm "$expanded_path"
                echo "✓ Removed: $expanded_path"
            else
                echo "Skipped: $expanded_path"
            fi
        fi
    fi
done < <(grep -A1 '"path":' "$CONFIG_FILE")

# Uninstall nushell if installed
if command -v nu &> /dev/null; then
    if prompt_yes_no "Would you like to uninstall nushell?"; then
        echo "Uninstalling nushell..."
        bash "$SCRIPT_DIR/nu/uninstall-nu.sh"
    fi
fi

echo "✨ Uninstall complete!"
