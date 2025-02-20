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

# Function to prompt for yes/no/all
function Prompt-YesNoAll {
    param([string]$Path)
    
    if ($script:AllYes) {
        return $true
    }
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Remove this symlink")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Skip this symlink")
        [System.Management.Automation.Host.ChoiceDescription]::new("&All", "Remove all remaining symlinks")
    )
    
    $decision = $Host.UI.PromptForChoice("Remove Symlink", "Remove symlink for $Path?", $choices, 1)
    
    if ($decision -eq 2) {
        $script:AllYes = $true
        return $true
    }
    
    return $decision -eq 0
}

Write-Host "🧹 Unapplying dotfiles configuration..."

# Ask for confirmation before proceeding
if (-not (Prompt-YesNo "Would you like to proceed with uninstallation?")) {
    Write-Host "Uninstallation cancelled."
    exit 0
}

# Initialize AllYes flag
$script:AllYes = $false

# Load and parse dotfiles configuration
$ConfigFile = "dotfiles.json"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "❌ Configuration file not found: $ConfigFile"
    exit 1
}

# Function to expand path
function Expand-CustomPath {
    param([string]$Path)
    return $Path.Replace("~", $env:USERPROFILE)
}

# Read configuration
$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

Write-Host "Removing symlinks..."
foreach ($mapping in $config.pathMappings) {
    $expandedPath = Expand-CustomPath $mapping.diskPath
    
    # Check if path exists and is a symlink
    if (Test-Path $expandedPath) {
        $item = Get-Item $expandedPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            if (Prompt-YesNoAll $expandedPath) {
                Remove-Item $expandedPath -Force
                Write-Host "✓ Removed: $expandedPath"
            } else {
                Write-Host "Skipped: $expandedPath"
            }
        }
    }
}

# Uninstall nushell if installed
if (Get-Command "nu" -ErrorAction SilentlyContinue) {
    if (Prompt-YesNo "Would you like to uninstall nushell?") {
        Write-Host "Uninstalling nushell..."
        & $PSScriptRoot/nu/uninstall-nu.ps1
    }
}

Write-Host "✨ Uninstall complete!"
