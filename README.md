## Setup new environment

```
cd ~
git clone https://github.com/n8behavior/dotfiles /tmp/dotfiles
mv /tmp/dotfiles/.git .
git restore .
.local/bin/bootstrap-dotfiles
```

## Maintain current environment

All paths in the `worktree` are ignored by default and must be explicitely
added in the `.gitigore`.
