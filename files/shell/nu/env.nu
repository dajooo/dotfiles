# Environment setup for Nushell

# Default env values
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Starship configuration
$env.STARSHIP_SHELL = "nu"

# Set up starship paths
$env.STARSHIP_CACHE_DIR = if $nu.os-info.name == "windows" {
    $"($env.LOCALAPPDATA)\\starship"
} else {
    "~/.cache/starship"
}

$env.STARSHIP_CONFIG = if $nu.os-info.name == "windows" {
    $"($env.APPDATA)\\starship.toml"
} else {
    "~/.config/starship.toml"
}

# Create cache directory if it doesn't exist
if not ($env.STARSHIP_CACHE_DIR | path exists) {
    mkdir $env.STARSHIP_CACHE_DIR
}

# Initialize starship
starship init nu | save -f $"($env.STARSHIP_CACHE_DIR)/init.nu"
