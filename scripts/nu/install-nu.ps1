# Check if winget is installed, otherwise install it
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..."
    # Download and install winget from GitHub
    $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller.msixbundle"
    $outFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Invoke-WebRequest -Uri $url -OutFile $outFile
    Add-AppxPackage -Path $outFile
}

if (-not (Get-Command "nu" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing nu..."
    winget install nushell
}

# Configure Windows Terminal
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    Write-Host "Configuring Windows Terminal..."
    
    # Read current settings
    $settings = Get-Content -Path $wtSettingsPath -Raw | ConvertFrom-Json
    
    # Create nushell profile
    $nuProfile = @{
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
    }
    
    # Set nushell as default profile
    $nuGuid = ($settings.profiles.list | Where-Object { $_.commandline -eq "nu.exe" }).guid
    if (-not $nuGuid) {
        # Generate new GUID if not present
        $nuGuid = [System.Guid]::NewGuid().ToString()
        ($settings.profiles.list | Where-Object { $_.commandline -eq "nu.exe" }).guid = $nuGuid
    }
    $settings.defaultProfile = $nuGuid
    
    # Save settings with UTF-8 encoding
    $settings | ConvertTo-Json -Depth 32 | Out-File -FilePath $wtSettingsPath -Encoding UTF8
    
    Write-Host "Windows Terminal configured with Nushell as default profile"
}

Write-Host "Done. nu is now installed."
