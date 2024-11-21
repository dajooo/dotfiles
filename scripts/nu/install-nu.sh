#!/bin/bash

# Function to install starship
install_starship() {
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

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

if ! command -v nu &> /dev/null; then
    echo "nu could not be found, installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        # Linux or macOS
        echo "Downloading nushell..."
        # Create temporary directory
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        # Use latest stable version
        VERSION="0.100.0"
        
        # Set architecture and OS suffix based on system
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ $(uname -m) == "arm64" ]]; then
                ARCH_SUFFIX="aarch64-apple-darwin"
            else
                ARCH_SUFFIX="x86_64-apple-darwin"
            fi
        else
            if [[ $(uname -m) == "aarch64" ]]; then
                ARCH_SUFFIX="aarch64-unknown-linux-gnu"
            else
                ARCH_SUFFIX="x86_64-unknown-linux-gnu"
            fi
        fi

        # Construct download URL
        DOWNLOAD_URL="https://github.com/nushell/nushell/releases/download/${VERSION}/nu-${VERSION}-${ARCH_SUFFIX}.tar.gz"
        echo "Downloading from: $DOWNLOAD_URL"
        
        # Download the release
        if ! wget -q "$DOWNLOAD_URL"; then
            echo "Failed to download nushell. Please check your internet connection and try again."
            exit 1
        fi
        
        ARCHIVE_NAME="nu-${VERSION}-${ARCH_SUFFIX}.tar.gz"
        
        # Extract archive
        echo "Extracting archive..."
        if ! tar xzf "$ARCHIVE_NAME"; then
            echo "Failed to extract archive"
            exit 1
        fi
        
        # Find the extracted directory
        EXTRACTED_DIR="nu-${VERSION}-${ARCH_SUFFIX}"
        if [ ! -d "$EXTRACTED_DIR" ]; then
            echo "Failed to find extracted directory"
            exit 1
        fi
        
        # Install nu binary
        echo "Installing nushell..."
        cd "$EXTRACTED_DIR"
        if ! sudo mv nu /usr/local/bin/; then
            echo "Failed to install nushell binary"
            exit 1
        fi
        sudo chmod +x /usr/local/bin/nu
        
        # Cleanup
        cd
        rm -rf "$TEMP_DIR"
        
        # Add nu to /etc/shells if not already present
        if ! grep -q "/usr/local/bin/nu" /etc/shells; then
            echo "Adding nu to /etc/shells..."
            echo "/usr/local/bin/nu" | sudo tee -a /etc/shells
        fi
        
        # Ask user if they want to set nu as default shell
        if prompt_yes_no "Would you like to set nushell as your default shell?"; then
            echo "Setting nu as default shell..."
            sudo chsh -s /usr/local/bin/nu $USER
            echo "Nushell is now your default shell."
            echo "To switch to nushell now without logging out, run: exec nu"
        else
            echo "Nushell installed but not set as default shell."
            echo "You can try nushell by running: nu"
        fi
        
        # Install starship if not present
        if ! command -v starship &> /dev/null; then
            install_starship
        fi
        
        echo "Nushell installed successfully!"
    else
        echo "Unsupported OS"
        exit 1
    fi
else
    echo "nu is already installed."
    
    # If nu is not the default shell, ask if user wants to make it default
    if [[ "$SHELL" != *"nu"* ]]; then
        if prompt_yes_no "Would you like to set nushell as your default shell?"; then
            echo "Setting nu as default shell..."
            sudo chsh -s /usr/local/bin/nu $USER
            echo "Nushell is now your default shell."
            echo "To switch to nushell now without logging out, run: exec nu"
        fi
    fi
    
    # Install starship if not present
    if ! command -v starship &> /dev/null; then
        install_starship
    fi
fi
