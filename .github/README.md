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
added in the `.gitigore`.

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
