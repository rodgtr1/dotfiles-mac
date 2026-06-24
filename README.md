# dotfiles-mac

My macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a **stow package**. The structure inside a package
mirrors the config's real path relative to `$HOME`, so `stow <package>`
symlinks it into the right place.

## Packages

| Package    | Symlinks to                                                        |
|------------|--------------------------------------------------------------------|
| `zsh`      | `~/.zshrc`, `~/.zshenv`, `~/.zprofile`                             |
| `starship` | `~/.config/starship.toml`                                          |
| `sidekick` | `~/.config/sidekick/config.toml`                                  |
| `zed`      | `~/.config/zed/settings.json`                                     |
| `nvim`     | `~/.config/nvim/`                                                  |
| `raycast`  | `~/.config/raycast/`                                               |
| `ghostty`  | `~/Library/Application Support/com.mitchellh.ghostty/config`       |
| `vscode`   | `~/Library/Application Support/Code/User/settings.json`            |

## Setup on a new Mac

One command does everything — installs Homebrew, all packages from the
`Brewfile`, and symlinks every dotfile package with stow:

```sh
xcode-select --install   # only if git isn't available yet
git clone git@github.com:rodgtr1/dotfiles-mac.git ~/dotfiles-mac
~/dotfiles-mac/bootstrap.sh
```

`bootstrap.sh` is idempotent, so it's safe to re-run any time.

### Manual / partial setup

```sh
brew bundle --file=~/dotfiles-mac/Brewfile   # just the packages
cd ~/dotfiles-mac
stow */                                       # all packages, or: stow zsh starship ...
```

### Managing packages

The `Brewfile` is the source of truth for installed software.

```sh
brew bundle --file=~/dotfiles-mac/Brewfile          # install everything listed
brew bundle check --file=~/dotfiles-mac/Brewfile    # what's missing?
brew bundle cleanup --file=~/dotfiles-mac/Brewfile  # uninstall anything not listed
brew bundle dump --force --describe --file=~/dotfiles-mac/Brewfile  # regenerate from this Mac
```

## Common commands (run from `~/dotfiles-mac`)

```sh
stow <pkg>       # link a package
stow -D <pkg>    # unlink
stow -R <pkg>    # relink (after adding files, or if an app replaced a symlink)
stow -n -v <pkg> # dry-run, verbose
```

## Notes

- VS Code and Sidekick rewrite their settings with atomic saves, which can
  occasionally replace a symlink with a regular file. If that happens, run
  `stow -R vscode` / `stow -R sidekick` to relink.
- Secrets (`gh/hosts.yml`, `sops` age keys) are intentionally excluded — see
  `.gitignore`.
