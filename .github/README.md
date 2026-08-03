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
git clone https://github.com/n8behavior/dotfiles /tmp/dotfiles
mv /tmp/dotfiles/.git .
git restore .
.local/bin/bootstrap-dotfiles
```

## Maintain current environment

All paths in the `worktree` are ignored by default and must be explicitly
added in the `.gitignore`.

## YubiKey login (FIDO2 / pam-u2f)

Touch + PIN replaces the password at the GDM greeter, the lock screen, `sudo`,
`su` and polkit. The key is a *primary* factor, not a second one: if it
succeeds you are in, and **any failure falls through to the password prompt**.
Nothing here can lock you out.

```
common-auth ──► pam_u2f.so   (priority 384, [success=end default=ignore])
                    │ success ──► done
                    │ fail    ──► pam_unix.so ──► password
```

### Why the origin is pinned

FIDO2 credentials are bound to the relying-party ID they were registered
against, and both `pamu2fcfg` and `pam_u2f` default it to `pam://$HOSTNAME`.
That silently produces credentials that only work on the machine that created
them. `.local/etc/fido-login.env` pins it to `pam://n8behavior` on both the
enroll and the verify side, so one mapping authenticates on every host.

**Changing `FIDO_ORIGIN` invalidates every enrolled credential.** The mapping
file records key handles but not the origin, so a mismatch is undetectable
until you actually try to authenticate — which is why `setup-fido-login`
self-tests with `pamtester` before it touches PAM.

### Commands

| Command | What it does |
|---|---|
| `enroll-fido-key` | Register one attached YubiKey against the pinned origin, append it to `~/.config/Yubico/u2f_keys`, and sync the mapping to passage. Refuses to run with two keys attached, with a key that has no FIDO PIN, or if the credential comes back without `+pin`. Run once per key. |
| `setup-fido-login` | Idempotent. Orders `u2f_keys` so the attached key's credential is first (see *Credential order* below), then installs the `pam-auth-update` profile and enables it, then asserts the profile reached `common-auth` and that `pam_u2f` appears nowhere else. Self-tests with `pamtester` first and aborts before changing PAM if that fails. Exits early — no touch, no PIN, no sudo — when the installed profile and `common-auth` already match what it would write; any drift (a changed `FIDO_ORIGIN`, new module options, a removed profile) triggers the full re-run. Called from `bootstrap-dotfiles`; a no-op until a key is enrolled. |

### Credential order

`pam_u2f` tries the credentials on the `sandman:` line **one full assertion at
a time, in file order** — it does not offer them all in a single assertion.
Normally that costs nothing: a check-only probe silently works out which
credential the attached key holds, and only that one gets a real assertion.
`nodetect` turns that probe off, so the module falls back to trying each
credential blind, and learns of a mismatch only *after* cueing a touch and
collecting a PIN. With every key in one shared mapping, the host holding the
second-listed credential pays a doomed touch+PIN before the real one:

```
cred 1 ──► cue + PIN ──► FIDO_ERR_NO_CREDENTIALS
cred 2 ──► cue + PIN ──► success
```

`setup-fido-login` runs that probe itself (`fido2-assert -G -t up=false`, which
needs no user presence and no PIN) and rewrites the local `u2f_keys` with the
attached key's credential first. Ordering is **local state only** — the copy in
passage stays canonical, and every host orders its own after `restore-secrets`.
Both keys still authenticate on both hosts; only the non-local one pays the
extra prompt.

Setting `uv=false` on the probe as well looks natural and is wrong: a YubiKey 5
rejects it with `FIDO_ERR_UNSUPPORTED_OPTION`. Leave `uv` alone.

### New machine

Mount the Recovery drive and run `bootstrap-dotfiles`. `restore-secrets` writes
`~/.config/Yubico/u2f_keys` from passage, and `setup-fido-login` picks it up at
the end. Both keys are already in the mapping, so no re-enrollment is needed —
only the key attached to that machine has to be present.

### New key

`enroll-fido-key` (appends to the same `sandman:` line), then push the mapping
to the Recovery drive with `sync-secrets push`. A key used on a new machine
also needs an age identity for passage — see the Recovery drive's README.

### Files

- `.local/bin/enroll-fido-key`, `.local/bin/setup-fido-login`
- `.local/etc/fido-login.env` — pinned `FIDO_ORIGIN` / `FIDO_APPID`, shared by both scripts
- `~/.config/Yubico/u2f_keys` — credential mapping, one line, one credential per key, attached key's credential first. Gitignored; lives in passage as `yubico/u2f_keys`, unordered
- `/usr/share/pam-configs/n8-u2f` — the profile, installed by `setup-fido-login`
- `/etc/pam.d/n8-u2f-selftest` — service used by `pamtester`; nothing else reads it
- `/etc/ssh/sshd_config.d/10-no-password-auth.conf` — see below

### Gotchas

- **The GNOME keyring stops auto-unlocking.** `pam_gnome_keyring` derives the
  keyring key from the password you typed; `pam_u2f` produces a signature over
  a random challenge and has no stable secret to hand it. Expect one unlock
  prompt per session. A non-interactive `git push` or `gh` call *before* you
  unlock will fail with `could not read Username`, because the token lives in
  the locked keyring.
- **Unlock after suspend needs `nodetect`.** The key stays on the USB bus
  across sleep, but it is still waking from USB suspend when GNOME starts the
  PAM conversation at lid-open. Without `nodetect`, `pam_u2f` sends a
  check-only probe first; the half-awake key fails it and the stack silently
  falls through to the password. `nodetect` skips the probe and starts the
  real assertion, whose PIN prompt gives the key the seconds it needs. The
  trade-off: an attached FIDO device with no enrolled credential now draws a
  touch cue that cannot succeed before the password prompt appears.
- **A second enrolled key costs a prompt if it sorts first.** `nodetect` means
  order in `u2f_keys` decides how many touch+PIN rounds you pay. Symptom:
  authenticating twice in a row on one host and once on another, with an
  identical mapping and PAM stack. `setup-fido-login` fixes the order — see
  *Credential order* above.
- **Escape restarts a stalled unlock.** If the lock screen ever lands on the
  password field instead of the PIN prompt, pressing Escape and interacting
  again starts a fresh PAM conversation, giving `pam_u2f` another shot at the
  key. Generic GNOME behavior, but it is the quick recovery for any future
  timing issue.
- **`sshd` includes `common-auth`.** With password auth enabled, a remote login
  would cue a touch on the authenticator attached to the *server*.
  `setup-fido-login` drops in `PasswordAuthentication no`. Pubkey auth is
  unaffected.
- **`NOPASSWD` in sudoers bypasses PAM entirely.** `sudo` then never consults
  `pam_u2f`, so no touch, no PIN. Keep `/etc/sudoers.d/sandman` renamed to
  `sandman.disabled` (sudo skips filenames containing a dot).
- **PIV is unreachable over SSH.** `pcsc-lite`'s polkit policy is
  `allow_active=yes / allow_inactive=no / allow_any=no`, and logind marks an
  ssh session `Remote=yes`. So `passage show` and anything else touching the
  PIV applet must be run at the machine. FIDO2 (`pam_u2f`) uses hidraw and is
  not affected. See the WSL2 section below for the polkit override.
- **Wrong PINs are expensive.** Three consecutive failures lock the key until
  reinsert; eight block it permanently, and a FIDO reset destroys every
  credential on it.

### Disabling it

Your password keeps working throughout, so this is only needed if `pam_u2f`
itself misbehaves:

```bash
sudo pam-auth-update --package --remove n8-u2f   # take the key out of the stack
sudo git -C /etc checkout common-auth            # or restore from etckeeper
```

From a locked screen: `Ctrl+Alt+F3`, log in with your password, then
`sudo loginctl unlock-session <id>` (`loginctl list-sessions` to find it).

## Gruvbox theme sync (dark / light)

GNOME's `org.gnome.desktop.interface color-scheme` is the single source of
truth. The system Quick Settings dark/light toggle — or the `theme-toggle`
command — flips it, and a user-level systemd service fans out to everything
else.

```
color-scheme ──► theme-sync.service ──► tmux, starship,
                 (gsettings monitor)    gnome-terminal default profile, GTK

                                     ┌► nvim (auto-dark-mode.nvim polls
                                        gsettings directly)
```

### Commands

| Command | What it does |
|---|---|
| `theme-toggle` | Flip `color-scheme` between `prefer-dark` and `default`. Bind to a keyboard shortcut if you want. |
| `theme-sync` | Idempotent fanout: rewrites `~/.config/tmux/theme.conf`, sed-edits the starship palette line, dconf-writes the 16-color palette of the single `Gruvbox` gnome-terminal profile (VTE reacts instantly, so open terminals flip live), sets the GTK theme. Runs automatically via the systemd listener. |
| `theme-sync-install` | One-time post-`git pull` setup — installs `Gruvbox-GTK-Theme` into `~/.themes` and enables the systemd service. `bootstrap-dotfiles` does the same work inline on fresh machines. |

### Files

- `.local/bin/theme-sync`, `theme-toggle`, `theme-sync-install`
- `.config/systemd/user/theme-sync.service` — `gsettings monitor` loop; `ExecStartPre` applies current state at login
- `.config/theme-sync.env` — gnome-terminal `Gruvbox` profile UUID (must match `setup-gnome-terminal-gruvbox` in `bootstrap-dotfiles`)
- `.config/tmux/theme.conf` — sourced by `.tmux.conf`; generated by `theme-sync` on each run (gitignored runtime state)
- `.config/starship.toml.in` — tracked template defining `gruvbox_dark` and `gruvbox_light` palettes; `theme-sync` seeds `.config/starship.toml` from it on first run (gitignored runtime file) and rewrites the `palette = …` line on toggle. Edit the `.in` template to make permanent changes.
- `.config/nvim/lua/plugins/colorscheme.lua` — loads `f-person/auto-dark-mode.nvim`, which polls gsettings and flips `vim.o.background`

### Requirements

- `sassc` (apt) — needed to compile Gruvbox-GTK-Theme. Included in `install-common-packages`.
- `f-person/auto-dark-mode.nvim` — pulled in by LazyVim; run `:Lazy sync` after first update.

## WSL2 Setup

### Mounting ext4 USB Drives and YubiKey Access

### Problem 1: Mounting ext4 USB Drives

The `wsl --mount` command **does not support USB/flash drives/SD card readers** — it only works with internal SATA/NVMe drives. Attempting to use it results in:

```
Error code: Wsl/Service/AttachDisk/MountDisk/HCS/0x8007000f
```

#### Solution: Use usbipd-win

1. **Install usbipd on Windows:**
   ```powershell
   winget install usbipd
   ```

2. **Install USB support in WSL:**
   ```bash
   sudo apt install linux-tools-generic hwdata usbutils
   ```

3. **Attach the USB device (from elevated PowerShell):**
   ```powershell
   usbipd list                          # Find your device's BUSID
   usbipd bind --busid <BUSID> --force  # One-time setup (may require reboot)
   usbipd attach --wsl --busid <BUSID>
   ```

4. **Mount in WSL:**
   ```bash
   lsblk                                    # Find the device (e.g., /dev/sde)
   sudo mkdir -p /mnt/usb
   sudo mount -t ext4 /dev/sdeX /mnt/usb   # Replace X with partition number
   ```

5. **Cleanup when done:**
   ```bash
   sudo umount /mnt/usb
   ```
   ```powershell
   usbipd detach --busid <BUSID>
   ```

---

### Problem 2: YubiKey Access in WSL2

After attaching a YubiKey via usbipd, commands like `ykman piv info` or `age-plugin-yubikey` fail with access denied errors, even though `lsusb` shows the device and `sudo` works.

#### Root Cause

Two separate permission issues:

1. **USB device permissions** — The device node (`/dev/bus/usb/...`) is owned by root
2. **Polkit policy** — WSL2 sessions aren't considered "active" local sessions, so polkit denies access to PC/SC smart card operations

#### Solution

**Step 1: Install required packages**
```bash
sudo apt install pcscd libpcsclite-dev
# Optional for debugging: sudo apt install pcsc-tools
```

**Step 2: Create udev rules for USB device access**
```bash
sudo tee /etc/udev/rules.d/70-yubikey.rules << 'EOF'
# YubiKey USB access for all users
SUBSYSTEM=="usb", ATTR{idVendor}=="1050", MODE="0666"
# YubiKey hidraw access
KERNEL=="hidraw*", ATTRS{idVendor}=="1050", MODE="0666"
EOF

sudo udevadm control --reload-rules
```

**Step 3: Create polkit rules for PC/SC access**

This is the critical fix — without this, card transactions fail even with correct USB permissions:

```bash
sudo tee /etc/polkit-1/rules.d/99-pcscd.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.debian.pcsc-lite.access_pcsc" ||
         action.id == "org.debian.pcsc-lite.access_card") &&
        subject.user == "sandman") {
        return polkit.Result.YES;
    }
});
EOF
```

Replace `sandman` with your username.

**Step 4: Restart pcscd**
```bash
sudo service pcscd restart
```

**Step 5: Reattach the YubiKey**

From elevated PowerShell:
```powershell
usbipd detach --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

**Step 6: Verify**
```bash
ykman info           # Should work without sudo
ykman piv info       # Should work without sudo
age-plugin-yubikey --list-all
```

---

### Quick Reference: Per-Session YubiKey Attachment

After initial setup, each WSL session requires reattaching the YubiKey:

```powershell
# From elevated PowerShell
usbipd attach --wsl --busid <BUSID>
```

```bash
# In WSL - restart pcscd after attach
sudo service pcscd restart
```

---

### Debugging Tips

| Command | Purpose |
|---------|---------|
| `lsusb \| grep -i yubi` | Verify WSL sees the USB device |
| `pcsc_scan` | Check if pcscd sees the smart card (requires `pcsc-tools`) |
| `ykman -l DEBUG piv info` | Verbose output for troubleshooting |
| `ls -la /dev/bus/usb/*/*` | Check USB device permissions |
| `ls -la /var/run/pcscd/` | Check pcscd socket permissions |
