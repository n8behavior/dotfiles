_NOTE: This README lives in `.github` as to not clutter `$HOME`_

## Setup new environment

```
cd ~
git clone https://github.com/n8behavior/dotfiles ~/.dotfiles
alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME'
.local/bin/bootstrap-dotfiles
```

## Maintain current environment

All paths in the `worktree` are ignored by default and must be explicitely
added in the `.gitigore`.
