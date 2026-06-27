# Brewfile — packages for a fresh macOS setup.
#
# Install everything:        brew bundle --file=~/dotfiles-mac/Brewfile
# See what would change:     brew bundle check --file=~/dotfiles-mac/Brewfile
# Remove anything not here:  brew bundle cleanup --file=~/dotfiles-mac/Brewfile
# Regenerate from this Mac:  brew bundle dump --force --describe --file=~/dotfiles-mac/Brewfile

# --- Taps ---
tap "fluxcd/tap"

# --- CLI tools ---
brew "age"             # modern file encryption
brew "ansible"         # automation / config management
brew "bun"             # JS runtime + package manager
brew "cmake"           # build system generator
brew "fd"              # fast, friendly `find`
brew "fzf"             # fuzzy finder
brew "gh"              # GitHub CLI
brew "lazygit"         # terminal UI for git
brew "neovim"          # editor
brew "ripgrep"         # fast `grep` (rg)
brew "rust"            # rust toolchain (cargo, rustc)
brew "sops"            # secrets encryption
brew "starship"        # shell prompt
brew "stow"            # dotfiles symlink manager
brew "uv"              # python package/project manager
brew "zsh-autosuggestions"  # grey type-ahead suggestions from history (sourced in .zshrc)

# --- Kubernetes ---
brew "kubernetes-cli"   # kubectl
brew "k9s"              # kubernetes TUI
brew "fluxcd/tap/flux"  # GitOps for Kubernetes

# --- Virtualization / local LLMs ---
brew "qemu"            # machine emulator / virtualizer
brew "ollama"          # run LLMs locally

# --- Apps ---
cask "raycast"          # launcher / productivity
cask "ghostty"          # terminal (config in ./ghostty)
cask "visual-studio-code" # editor (config in ./vscode)
cask "zed"              # editor (config in ./zed)
cask "claude-code"      # Anthropic's agentic coding CLI
cask "codex"            # OpenAI's coding agent CLI

# --- Fonts ---
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
