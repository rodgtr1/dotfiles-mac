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
brew "cmake"           # build system generator
brew "fd"              # fast, friendly `find`
brew "fzf"             # fuzzy finder
brew "gh"              # GitHub CLI
brew "lazygit"         # terminal UI for git
brew "neovim"          # editor
brew "ripgrep"         # fast `grep` (rg)
brew "sops"            # secrets encryption
brew "starship"        # shell prompt
brew "stow"            # dotfiles symlink manager
brew "zsh-autosuggestions"  # grey type-ahead suggestions from history (sourced in .zshrc)
# Note: bun, rust (rustup), and uv are installed via their own native installers
# in bootstrap.sh (step 4), not Homebrew — they ship self-updating installers and
# rustup provides toolchain management the brew 'rust' formula lacks.

# --- Kubernetes ---
brew "kubernetes-cli"   # kubectl
brew "k9s"              # kubernetes TUI
brew "fluxcd/tap/flux"  # GitOps for Kubernetes

# --- Virtualization / local LLMs ---
brew "qemu"            # machine emulator / virtualizer
cask "ollama-app"      # run LLMs locally — native menubar app (self-updating)

# --- Apps ---
cask "raycast"          # launcher / productivity
cask "ghostty"          # terminal (config in ./ghostty)
cask "visual-studio-code" # editor (config in ./vscode)
cask "zed"              # editor (config in ./zed)
# Note: the AI coding CLIs (Claude Code, Codex) are installed via their own native
# installers in bootstrap.sh (step 4), not Homebrew. Their brew packages lag behind
# and disable the CLIs' built-in auto-updaters.

# --- Fonts ---
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
