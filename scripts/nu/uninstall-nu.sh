#!/bin/bash
# This script is used to uninstall nu from the system
if command -v nu &> /dev/null; then
    echo "Uninstalling nu..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo rm -f /usr/local/bin/nu
        echo "Nushell uninstalled successfully!"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew uninstall nu
    else
        echo "Unsupported OS"
        exit 1
    fi
else
    echo "nu is not installed."
fi
