. "$HOME/.cargo/env"

# Put the active nvm node on PATH directly. This avoids sourcing nvm.sh (~0.3s)
# while still making node/npm/npx real binaries in EVERY shell — including
# non-interactive and agent shells that never load .zshrc. (nvm.sh just adds this
# bin dir to PATH; we do it ourselves.) `nvm use` later still wins because it
# prepends ahead of this entry.
export NVM_DIR="$HOME/.nvm"
typeset -U path PATH
() {
  local node_bins=("$NVM_DIR"/versions/node/*/bin(Nn))
  (( ${#node_bins} )) && path=("${node_bins[-1]}" $path)
}
