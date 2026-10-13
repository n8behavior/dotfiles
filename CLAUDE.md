# dotfiles

The home directory is the work tree of the dotfiles repo, n8behavior/dotfiles.
These rules are for that repo, not for the repos under `~/src`.

- Commit straight to `main` and push. No branches, no pull requests.
- After pushing, refresh the Recovery drive's clone, which the drive's
  `sync-secrets` and `ha-backup` links run from:
  `git -C "$(findmnt -n -o TARGET -S LABEL=Recovery)"/dotfiles pull --ff-only`.
  Skip it if the drive is not mounted, and say so.
