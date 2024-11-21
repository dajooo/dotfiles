# One-click installer for dotfiles

$DotfilesDir = "$env:USERPROFILE\.dotfiles"

# Function to prompt for yes/no
function Prompt-YesNo {
    param([string]$Question)
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed with the action")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Skip this action")
    )
    
    $decision = $Host.UI.PromptForChoice("Confirmation", $Question, $choices, 1)
    return $decision -eq 0
}

Write-Host "🚀 Welcome to dotfiles installer!"

# Show installation plan
Write-Host "`nThis script will:"
Write-Host "1. Install required dependencies (git, winget) if missing"
Write-Host "2. Clone dotfiles repository to $DotfilesDir"
Write-Host "3. Initialize and update git submodules"
Write-Host "4. Install nushell and starship"
Write-Host "5. Configure Windows Terminal"
Write-Host "6. Set up shell configuration`n"

# Ask for confirmation before proceeding
if (-not (Prompt-YesNo "Would you like to proceed with the installation?")) {
    Write-Host "Installation cancelled."
    exit 0
}

# Check and install dependencies
Write-Host "`n🔍 Checking dependencies..."

# Check for git
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed."
    if (Prompt-YesNo "Would you like to install Git?") {
        # Check for winget
        if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing winget..."
            $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller.msixbundle"
            $outFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
            Invoke-WebRequest -Uri $url -OutFile $outFile
            Add-AppxPackage -Path $outFile
        }
        winget install -e --id Git.Git
    } else {
        Write-Host "❌ Git is required for installation. Exiting."
        exit 1
    }
}

# Clone repository if it doesn't exist
if (-not (Test-Path $DotfilesDir)) {
    Write-Host "`n📦 Cloning repository..."
    git clone https://github.com/dajooo/dotfiles.git $DotfilesDir
    Set-Location $DotfilesDir
    Write-Host "📥 Initializing submodules..."
    git submodule update --init --recursive
}
else {
    Write-Host "`n📂 Repository already exists."
    if (Prompt-YesNo "Would you like to update it?") {
        Set-Location $DotfilesDir
        git pull
        Write-Host "📥 Updating submodules..."
        git submodule update --init --recursive
    }
}

# Change to dotfiles directory if not already there
Set-Location $DotfilesDir

# Run installation
Write-Host "`n⚙️ Installing nushell..."
& .\scripts\nu\install-nu.ps1

Write-Host "`n🔧 Applying configuration..."
& .\scripts\apply.ps1

Write-Host "`n✨ Installation complete!"
Write-Host "You can now:"
Write-Host "1. Start Windows Terminal to use nushell (it's set as the default profile)"
Write-Host "2. Run 'nu' from any terminal to try nushell"
