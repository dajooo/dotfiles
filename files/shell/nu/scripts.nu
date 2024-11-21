use $"($nu.default-config-dir)/starship.nu"
source $"($nu.default-config-dir)/zoxide.nu"
source $"($nu.default-config-dir)/k8s.nu"

# Completions
source $"($nu.default-config-dir)/scripts/custom-completions/pnpm/pnpm-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/cargo/cargo-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/make/make-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/git/git-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/npm/npm-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/poetry/poetry-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/rustup/rustup-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/vscode/vscode-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/winget/winget-completions.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/auto-generate/parse-help.nu"
source $"($nu.default-config-dir)/scripts/custom-completions/auto-generate/parse-fish.nu"

# Custom aliases
alias code = codium