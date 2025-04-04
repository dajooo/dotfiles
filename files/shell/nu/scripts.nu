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

let home_dir = if $nu.os-info.name == "windows" { $env.USERPROFILE } else { $env.HOME }
$env.path ++= [$home_dir + "/.fnm"]
$env.path ++= [$home_dir + "/.fnm/aliases/default/bin"]
