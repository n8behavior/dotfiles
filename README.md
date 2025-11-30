# dotfiles

1. Attach the X10 Recovery drive
2. run the setup

   ```
   /media/sandman/Recovery/setup-sandman
   ```

## Setup without Recovery Drive

`gh` will need authorized with `gh auth token` and SSH and GPG keys will be missing

```
sudo apt update && sudo apt install -y git
cd ~
#tar -xf /media/sandman/Recovery/secrets/secrets.tar
git clone https://github.com/n8behavior/dotfiles /tmp/dotfiles
mv /tmp/dotfiles/.git .
git restore .
.local/bin/bootstrap-dotfiles
```

## Maintain current environment

All paths in the `worktree` are ignored by default and must be explicitly
added in the `.gitigore`.
