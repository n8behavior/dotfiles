alias hist="tail -qn1000 ~/.bash_history{,_*} | sed '\$!N;s/\n/ /' | cut -c2- | sort -n | cut -c12- | uniq"
alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME'
alias vi=nvim.appimage
alias vim=nvim.appimage
alias clear_nvim='rm -rf /home/jack/.local/share/nvim /home/jack/.local/state/nvim /home/jack/.cache/nvim'
