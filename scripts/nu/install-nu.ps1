# Check if winget is installed, otherwise install it
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..."
    # Download and install winget from GitHub
    $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller.msixbundle"
    $outFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Invoke-WebRequest -Uri $url -OutFile $outFile
    Add-AppxPackage -Path $outFile
}

# Install Nushell if not already installed
if (-not (Get-Command "nu" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Nushell..."
    winget install nushell
}

# Install Starship if not already installed
if (-not (Get-Command "starship" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Starship..."
    winget install starship
}

# Configure Windows Terminal
<# $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    Write-Host "Configuring Windows Terminal..."
    
    # Read current settings
    $settings = Get-Content -Path $wtSettingsPath -Raw | ConvertFrom-Json
    
    # Generate a new GUID for the profile
    $nuGuid = [System.Guid]::NewGuid().ToString()
    
    # Create nushell profile
    $nuProfile = [PSCustomObject]@{
        guid = $nuGuid
        name = "Nushell"
        commandline = "nu.exe"
        icon = "`u{1F6E0}"  # Unicode wrench emoji
        startingDirectory = "%USERPROFILE%"
        hidden = $false
    }
    
    # Check if profile already exists
    $existingProfile = $settings.profiles.list | Where-Object { $_.commandline -eq "nu.exe" }
    if (-not $existingProfile) {
        # Add new profile
        $settings.profiles.list += $nuProfile
    } else {
        # Update existing profile
        $existingProfile.guid = $nuGuid
        $existingProfile.name = $nuProfile.name
        $existingProfile.icon = $nuProfile.icon
        $existingProfile.startingDirectory = $nuProfile.startingDirectory
        $existingProfile.hidden = $nuProfile.hidden
    }
    
    # Set nushell as default profile
    $settings.defaultProfile = $nuGuid
    
    # Convert settings to JSON with proper formatting
    $jsonSettings = $settings | ConvertTo-Json -Depth 32
    
    # Ensure the JSON is properly formatted (no trailing commas)
    $jsonSettings = $jsonSettings -replace ',(\s*[}\]])', '$1'
    
    # Save settings with UTF-8 encoding and no BOM
    [System.IO.File]::WriteAllText($wtSettingsPath, $jsonSettings)
    
    Write-Host "Windows Terminal configured with Nushell as default profile"
} #>

Write-Host "Done. Nushell and Starship are now installed and configured."
