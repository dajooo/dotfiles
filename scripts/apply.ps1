# Install nushell if not already installed
& $PSScriptRoot\nu\install-nu.ps1

# Apply configuration using nushell script
nu $PSScriptRoot\apply.nu
