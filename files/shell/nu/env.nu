# Nushell Environment Config File
# version = "0.86.0"

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

# Check if starship is available
def has_starship [] {
    not (which starship | is-empty)
}

# Initialize starship if available
if (has_starship) {
    $env.STARSHIP_SHELL = "nu"
    
    # Set up the starship cache directory
    let cache_dir = if $nu.os-info.name == "windows" {
        $"($env.LOCALAPPDATA)/starship"
    } else {
        $"($env.HOME)/.cache/starship"
    }

    mkdir $cache_dir
    starship init nu | save -f $"($cache_dir)/init.nu"

    # Set up prompt command to use starship
    $env.PROMPT_COMMAND = { starship prompt }
    $env.PROMPT_COMMAND_RIGHT = { "" }
} else {
    # Fallback prompt if starship is not available
    $env.PROMPT_COMMAND = { build-string (date now | format date '%x %X') " " ($env.PWD | str replace $nu.home-path "~") }
    $env.PROMPT_COMMAND_RIGHT = { "" }
}

# Empty prompt indicators to let starship handle everything
$env.PROMPT_INDICATOR = { "" }
$env.PROMPT_INDICATOR_VI_INSERT = { "" }
$env.PROMPT_INDICATOR_VI_NORMAL = { "" }
$env.PROMPT_MULTILINE_INDICATOR = { "" }
