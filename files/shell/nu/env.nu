# Environment setup for Nushell

# Default env values
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

$env.STARSHIP_CONFIG = if $nu.os-info.name == "windows" {
    $"($env.APPDATA)\\starship.toml"
} else {
    "~/.config/starship.toml"
}