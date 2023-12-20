_NOTE: This README lives in `.github` as to not clutter `$HOME`_


```
cd ~
git clone https://github.com/n8behavior/dotfiles ~/.dotfiles
alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME'
.local/bin/bootstrap-dotfiles
```
