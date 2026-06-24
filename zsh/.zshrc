# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Homebrew paths without running `brew shellenv` on every shell startup.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
fpath=("/opt/homebrew/share/zsh/site-functions" "$HOME/.bun" $fpath)
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# PATH additions. Homebrew's bin/sbin first (replaces `eval "$(brew shellenv)"`),
# then cargo, windsurf, bun, lmstudio, go, local bin.
path=(
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  "$HOME/.cargo/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.lmstudio/bin"
  "$HOME/go/bin"
  $path
)
typeset -U path fpath
export PATH
export BUN_INSTALL="$HOME/.bun"

# Ghostty sets a TERM that some tools don't recognize.
if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
  export TERM=xterm-256color
fi

# --- Startup speed tweaks ---
# Skip the slow "insecure completion directories" security audit on every start.
export ZSH_DISABLE_COMPFIX=true
# Don't run the update-check git fetch on startup.
zstyle ':omz:update' mode disabled

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# --- Optional Oh My Zsh settings (uncomment to enable) ---
# CASE_SENSITIVE="true"                    # <--- case-sensitive tab completion
# HYPHEN_INSENSITIVE="true"                # <--- treat _ and - as interchangeable in completion
# zstyle ':omz:update' frequency 13        # <--- how often (days) to auto-update OMZ
# DISABLE_MAGIC_FUNCTIONS="true"           # <--- fix mangled pasted URLs/text
# DISABLE_LS_COLORS="true"                 # <--- turn off colored ls output
# DISABLE_AUTO_TITLE="true"                # <--- stop OMZ from setting the terminal title
# ENABLE_CORRECTION="true"                 # <--- "did you mean...?" command autocorrection
# COMPLETION_WAITING_DOTS="true"           # <--- show dots while completion loads
# DISABLE_UNTRACKED_FILES_DIRTY="true"     # <--- faster git status in huge repos (ignores untracked)
# HIST_STAMPS="mm/dd/yyyy"                 # <--- add timestamps to `history` output
# ZSH_CUSTOM=/path/to/new-custom-folder    # <--- use a different custom-config folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Dropped the heavy `git` plugin (its aliases went unused; starship already shows
# git status, and zsh ships its own git completion).
plugins=(
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'
export VISUAL='nvim'

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias k="kubectl";
alias n="nvim";

cpp() {
  claude -p "$*"
}

# Set up fzf key bindings and fuzzy completion (only if fzf is installed).
if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"

# Lazy-load nvm: sourcing nvm.sh eagerly cost ~0.3s on every shell. Instead we
# define lightweight shims that load nvm the first time you actually run node/npm.
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unset -f nvm node npm npx corepack yarn pnpm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()      { _load_nvm; nvm "$@"; }
node()     { _load_nvm; node "$@"; }
npm()      { _load_nvm; npm "$@"; }
npx()      { _load_nvm; npx "$@"; }
corepack() { _load_nvm; corepack "$@"; }
yarn()     { _load_nvm; yarn "$@"; }
pnpm()     { _load_nvm; pnpm "$@"; }

# Sidekick shell integration
[[ "$TERM_PROGRAM" == "Sidekick" ]] && source "$HOME/.config/sidekick/shell-integration/sidekick.zsh"
