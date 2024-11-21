# This script is used to uninstall nu from the system
if (Get-Command "nu" -ErrorAction SilentlyContinue) {
    Write-Host "Uninstalling nu..."
    winget uninstall nushell
} else {
    Write-Host "nu is not installed."
}

Write-Host "Done."
