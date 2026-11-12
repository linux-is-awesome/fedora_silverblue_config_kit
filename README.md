# Fedora Silverblue Config Kit

Shell scripts that set up a fresh Fedora Silverblue desktop: fonts, themes, packages, boot and security tweaks. Run them from one interactive menu, or run any script on its own.

## Usage

```bash
git clone https://github.com/linux-is-awesome/fedora-silverblue-config-kit.git
cd fedora-silverblue-config-kit
./setup
```

Pick an item by number. `sudo` is requested only when a script needs it. Anything installed with `rpm-ostree` needs a reboot to take effect.

To run a script directly:

```bash
./scripts/install-ubuntu-fonts --help
```

## Scripts

**Boot and disk**
- `backup-luks-header`: save a LUKS header to a directory you choose
- `hide-grub-menu`: hide GRUB at boot (Esc still opens it)
- `enable-tpm-unlock`: unlock LUKS at boot with TPM2

**System packages**
- `remove-base-apps`: remove base-image apps with `rpm-ostree override` (edit `config/remove-base-apps.list`)
- `install-virt-manager`: native QEMU/KVM, libvirt and virt-manager
- `enable-host-monitoring`: RAPL power, nethogs, SMART and sensors access for system monitors
- `enable-samba`: Samba usershares, with `~/Public` following GNOME File Sharing

**Fonts**
- `install-ubuntu-fonts`: Ubuntu, Ubuntu Sans and Ubuntu Sans Mono, system-wide
- `install-dejavu-fonts`: DejaVu, system-wide
- `install-microsoft-fonts`: Microsoft core fonts, system-wide
- `configure-ubuntu-fonts`: Ubuntu-style fontconfig and GNOME font settings

**Appearance**
- `install-adw-gtk3`: adw-gtk3 theme for the host and Flatpak
- `install-tela-icons`: Tela icons, including Flatpak access
- `enable-desktop-theme-sync`: adw light/dark + system GTK settings.ini
- `enable-gdm-session-sync`: live sync session settings/monitors into GDM on change

**Desktop and auth**
- `bind-terminal-shortcut`: bind Ctrl+Alt+T to `xdg-terminal-exec`
- `disable-printer-auth`: manage printers without a polkit password
- `enable-sudo-pwfeedback`: show asterisks when typing a sudo password
- `disable-sudo-fingerprint`: password-only sudo and polkit, login fingerprint unchanged

Where it makes sense, scripts support `--undo`. Run a script with `--help` to see its options.

## Layout

```text
setup       interactive menu
scripts/    one script per task
lib/        programs installed under /usr/local/lib
config/     files the scripts install
```

## Requirements

- Fedora Silverblue (GNOME)
- `bash` and `sudo`
- Network access for scripts that download fonts or themes

## Warning

These scripts change system files such as PAM, polkit, GRUB, LUKS and sudoers. Read a script before running it. They are written for one desktop, so review the options before applying them to yours.
