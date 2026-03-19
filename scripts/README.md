# Scripts

Custom shell scripts.

## Available Scripts

| Script | Description |
|--------|-------------|
| `kcs` | Kubernetes context switcher via fzf |
| `bmaster` | Checkout master and pull from upstream |
| `gws` | Git worktree switcher via fzf |

## Installation

Run `install.sh` to symlink all scripts to `/usr/local/bin/`:

```sh
./scripts/install.sh
```

This will create symbolic links for each executable script in this directory.

Some scripts need a shell wrapper to affect the current shell (e.g. `cd`). Add the following to your `~/.zshrc`:

```zsh
gws() { local dir; dir=$(command gws "$@") && cd "$dir"; }
```
