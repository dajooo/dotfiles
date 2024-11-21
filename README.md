# Dotfiles

My personal dotfiles for shell configuration, focusing on nushell with starship prompt.

## Quick Install

### Windows
```powershell
powershell -c "irm https://raw.githubusercontent.com/dajooo/dotfiles/main/install.ps1 | iex"
```

### Linux/macOS
```bash
curl -fsSL https://raw.githubusercontent.com/dajooo/dotfiles/main/install.sh | bash
```

The installer will:
1. Check for required dependencies
2. Ask for confirmation before installing anything
3. Clone the repository to ~/.dotfiles
4. Install and configure nushell and starship
5. Set up appropriate configuration for your platform

## Dependencies

The installer will check for and offer to install these dependencies:

### Windows
- Git
- Windows Terminal (recommended)
- Winget (for package installation)

### Linux/macOS
- Git
- Curl
- Wget
- Sudo (with appropriate permissions)

## What's Included

- Nushell configuration with:
  - Clean, minimal setup
  - Starship prompt integration
  - Git aliases and helpers
  - Development utilities

- Windows-specific:
  - Windows Terminal integration
  - Nushell set as default profile

- Unix-specific:
  - Optional default shell configuration
  - Full starship integration

## Manual Installation

If you prefer to install manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/dajooo/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the installation:
   - Windows: `.\apply.ps1`
   - Unix: `./apply.sh`

## Updating

The dotfiles can be updated by running the install script again (it will ask for confirmation), or manually:

```bash
cd ~/.dotfiles
git pull
./apply.sh  # or .\apply.ps1 on Windows
```

## Uninstalling

To remove the configuration:

- Windows: `.\unapply.ps1`
- Unix: `./unapply.sh`

The uninstall process will:
1. Ask for confirmation before proceeding
2. Prompt for each symlink removal (with option to remove all)
3. Optionally uninstall nushell if requested

You can use the 'all' option during symlink removal to skip individual confirmations.
