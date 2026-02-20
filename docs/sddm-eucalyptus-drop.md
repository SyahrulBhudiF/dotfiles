# SDDM Eucalyptus Drop on Fedora

This guide explains how to install and use the **Eucalyptus Drop** SDDM theme on Fedora, plus a few Fedora-specific notes.

## Requirements

- **SDDM >= 0.21.0**
- **Qt 6** including:
  - Qt5 Compatibility Module
  - Qt SVG

### Fedora packages

```/dev/null/packages.txt#L1-1
sudo dnf install sddm qt6-qtbase qt6-qtbase-gui qt6-qtsvg qt6-qt5compat
```

If you're on KDE, SDDM is typically already installed.

## Step 1: Switch from GDM to SDDM

If another display manager (like GDM) is active, disable it first then enable SDDM:

```/dev/null/switch-dm.txt#L1-3
sudo systemctl disable --now gdm
sudo systemctl enable sddm
```

> **Note:** Don't start SDDM yet — install the theme first so it's ready on first boot.

## Step 2: Install the theme

### Option A: KDE Plasma settings (KDE users only)

1. Open **System Settings** → **Startup and Shutdown** → **Login Screen (SDDM)**.
2. Click **Get New Themes**.
3. Search for **Eucalyptus Drop** and install.
4. Select it and apply.

If you don't see the SDDM settings page, install the `sddm-kcm` package first.

### Option B: Manual install from the release zip (all desktops)

1. Download the latest release `.zip` from the [upstream repo](https://gitlab.com/Matt.Jolly/sddm-eucalyptus-drop/-/releases).
2. Extract it into the SDDM themes directory:

```/dev/null/install.txt#L1-2
sudo mkdir -p /usr/share/sddm/themes/eucalyptus-drop
sudo unzip -o ~/Packages/sddm-eucalyptus-drop-v2.0.0.zip -d /usr/share/sddm/themes/eucalyptus-drop
```

> Adjust the zip path if you downloaded it elsewhere (e.g. `~/Downloads/`).

3. Verify the theme landed correctly:

```/dev/null/verify.txt#L1-1
ls /usr/share/sddm/themes/eucalyptus-drop/
```

You should see `metadata.desktop`, `theme.conf`, `Main.qml`, etc.

## Step 3: Activate the theme

Create or edit the SDDM config:

```/dev/null/mkdir.txt#L1-2
sudo mkdir -p /etc/sddm.conf.d
sudo nano /etc/sddm.conf.d/sddm.conf
```

Add:

```/dev/null/sddm.conf#L1-2
[Theme]
Current=eucalyptus-drop
```

Reference default config (if needed): `/usr/lib/sddm/sddm.conf.d/sddm.conf`

## Step 4: Start SDDM

Now start (or restart) SDDM:

```/dev/null/start.txt#L1-1
sudo systemctl start sddm
```

Or simply reboot:

```/dev/null/reboot.txt#L1-1
sudo reboot
```

## Preview changes without logging out

You can preview the theme from within your running desktop session:

```/dev/null/preview.txt#L1-1
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/eucalyptus-drop
```

## Customize the theme

Edit the theme config file:

```/dev/null/edit-theme.txt#L1-1
sudo nano /usr/share/sddm/themes/eucalyptus-drop/theme.conf
```

Common options:

| Option | Description |
|--------|-------------|
| `Background` | Path to background image (relative to theme dir) |
| `AccentColour` | Highlight color (HEX or Qt color name) |
| `MainColour` | Primary text/element color |
| `FullBlur` / `PartialBlur` | Enable blur effects |
| `BlurRadius` | Blur strength (keep ≤100 for performance) |
| `Font` / `FontSize` | Typography settings |
| `HeaderText` | Greeting text (e.g. `"Welcome!"`) |
| `FormPosition` | `left`, `center`, or `right` |
| `RoundCorners` | Border radius in pixels |

After editing, re-run the preview command above to see changes instantly.

## Troubleshooting

### Theme doesn't appear / fallback theme loads

- Verify the theme directory exists: `ls /usr/share/sddm/themes/eucalyptus-drop/`
- Ensure `Current=eucalyptus-drop` is set under `[Theme]` in `/etc/sddm.conf.d/sddm.conf`.
- Check file ownership: `ls -la /usr/share/sddm/themes/eucalyptus-drop/`

### SDDM fails to start or theme is broken

- Ensure Qt6, Qt5Compat, and QtSvg packages are installed.
- Verify SDDM version: `sddm --version` (needs >= 0.21.0).
- Check logs:

```/dev/null/logs.txt#L1-1
journalctl -u sddm -b
```

### Black screen or UI glitches

- Test with blur disabled (`FullBlur=false`, `PartialBlur=false`).
- Try a smaller `BlurRadius`.

### "File already exists" when enabling SDDM

If you see `Failed to preset unit: File '/etc/systemd/system/display-manager.service' already exists`, make sure you disabled the other display manager first:

```/dev/null/fix-symlink.txt#L1-2
sudo systemctl disable --now gdm
sudo systemctl enable --now sddm
```

## Upstream project

Repository: https://gitlab.com/Matt.Jolly/sddm-eucalyptus-drop/