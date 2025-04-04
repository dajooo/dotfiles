# One-click installer for dotfiles
param(
    [switch]$y = $false
)

# Check if script is being run via Invoke-Expression with -y flag or if DOTFILES_AUTO_YES is set
# This is needed because parameters can't be directly passed to scripts run via iex
if ($MyInvocation.Line -match '\s+-y\b' -or $MyInvocation.Line -match '\s+/y\b' -or $env:DOTFILES_AUTO_YES -eq 'true') {
    $y = $true
}

$DotfilesDir = "$env:USERPROFILE\.dotfiles"

# Function to prompt for yes/no
function Prompt-YesNo {
    param(
        [string]$Question,
        [switch]$AutoYes = $false
    )
    
    # If -y flag is set, automatically return true
    if ($AutoYes) {
        return $true
    }
    
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
if (-not (Prompt-YesNo -Question "Would you like to proceed with the installation?" -AutoYes $y)) {
    Write-Host "Installation cancelled."
    exit 0
}

# Check and install dependencies
Write-Host "`n🔍 Checking dependencies..."

# Check for git
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed."
    if (Prompt-YesNo -Question "Would you like to install Git?" -AutoYes $y) {
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
    if (Prompt-YesNo -Question "Would you like to update it?" -AutoYes $y) {
        Set-Location $DotfilesDir
        
        # Initialize variables
        $skipUpdate = $false
        $stashed = $false
        
        # Check for local changes
        $hasChanges = (git status --porcelain)
        if ($hasChanges) {
            Write-Host "Local changes detected in the repository."
            if ($y) {
                # In non-interactive mode, default to skipping the update
                $choice = 2
            } else {
                $choice = $Host.UI.PromptForChoice(
                    "Local Changes",
                    "How would you like to handle local changes?",
                    @(
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Stash", "Stash changes and reapply after update"),
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Reset", "Discard local changes"),
                    [System.Management.Automation.Host.ChoiceDescription]::new("&S&kip", "Skip update to preserve changes")
                ),
                2  # Default to Skip
            )
            }
            
            switch ($choice) {
                0 {
                    Write-Host "Stashing local changes..."
                    git stash
                    $stashed = $true
                }
                1 {
                    Write-Host "Discarding local changes..."
                    git reset --hard
                }
                2 {
                    Write-Host "Skipping repository update to preserve your local changes."
                    $skipUpdate = $true
                }
            }
        }
        
        if (-not $skipUpdate) {
            Write-Host "Updating repository..."
            git pull
            Write-Host "📥 Initializing submodules..."
            git submodule update --init --recursive
            
            # Apply stashed changes if needed
            if ($stashed) {
                Write-Host "Reapplying stashed changes..."
                git stash pop
            }
        }
    }
}

# Change to dotfiles directory if not already there
Set-Location $DotfilesDir

# Run installation
Write-Host "`n⚙️ Installing nushell..."
& .\scripts\nu\install-nu.ps1

Write-Host "`n🔧 Applying configuration..."
# Set environment variable for auto-yes if -y flag is set
if ($y) {
    $env:DOTFILES_AUTO_YES = "true"
} else {
    $env:DOTFILES_AUTO_YES = "false"
}
nu .\scripts\apply.nu

Write-Host "`n✨ Installation complete!"
Write-Host "You can now:"
Write-Host "1. Start Windows Terminal to use nushell (it's set as the default profile)"
Write-Host "2. Run 'nu' from any terminal to try nushell"
