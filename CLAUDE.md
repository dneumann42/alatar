# Alatar - A Wizard's Linux Environment

## Project Overview

Alatar is a personal system configuration and maintenance toolkit for Linux built primarily with **Tcl/Tk** for graphical applications and Bash for system scripts. It provides:

- **Dotfile management**: Centralized configuration with symlink deployment (dotfiles stored in `alatar_dots/`)
- **Package abstraction**: Logical package names mapped to distro-specific packages
- **Unified theming**: Single-source color theming via wallust across 25+ applications
- **Utility scripts**: Window management, media control, wallpaper handling, and more
- **TCL/Tk GUI tools**: System management interfaces (nomicron power menu, help browser, path editor)

The project is named after Alatar, one of the Blue Wizards from Tolkien's legendarium.

## Target Environment

- **Distro**: openSUSE Tumbleweed (primary), with historical support for Fedora/Arch
- **Display Server**: Wayland
- **Window Manager**: Sway (i3-compatible Wayland compositor)
- **Shell**: Zsh
- **Terminal**: Ghostty/Kitty with Zellij multiplexer

## Known Issues

### Graphical Authentication for Privileged Applications

**Context**: Applications that require elevated privileges need special handling in a graphical environment.

**Solutions**:

1. **For PolicyKit-aware applications**: Use `pkexec`
   ```bash
   exec setsid pkexec /path/to/app &
   ```

2. **For Myrlyn (openSUSE package manager)**: Use the provided wrapper
   ```bash
   exec setsid myrlyn-sudo &
   ```
   The `myrlyn-sudo` wrapper (at `/usr/bin/myrlyn-sudo`) handles:
   - Graphical password prompt via `myrlyn-askpass`
   - Preserving WAYLAND_DISPLAY, XDG_RUNTIME_DIR, and other environment variables
   - Proper sudo authentication with `sudo -A`

3. **General approach**: Check if the application provides its own graphical sudo wrapper before attempting pkexec or direct sudo calls.

**Status**: Fixed in `nomicron.tcl` - `do_software` now uses `myrlyn-sudo`.

## Directory Structure

```
~/.alatar/
├── bin2/                   # Main CLI entry points (Tcl-based)
│   ├── alatar.tcl         # Primary CLI tool
│   ├── dots.tcl           # Dotfile deployment module
│   ├── packages.tcl       # Package management module
│   └── tools.tcl          # Shared Tcl utilities
├── bin/                    # DEPRECATED - legacy bash scripts
├── scripts/               # Utility scripts
│   ├── pape.sh           # Wallpaper + wallust integration
│   ├── media.sh          # MPRIS media control for Waybar
│   ├── focus-*.tcl       # Workspace management scripts
│   └── launch-floating-* # Floating window launchers
├── tools/                 # Tcl/Tk GUI applications and shared libraries
│   ├── theme.tcl         # Wallust theme loading for TCL/Tk
│   ├── ui.tcl            # Common widget definitions
│   ├── help.tcl          # Help system GUI
│   ├── nomicron.tcl      # Power menu (shutdown/restart/logout)
│   ├── pathedit.tcl      # PATH environment editor
│   └── focus-*.tcl       # Window focus helpers
└── alatar_dots/          # DOTFILES REPOSITORY (all application configs)
    ├── applications/     # Desktop files (deployed to ~/.local/share/applications)
    ├── openSUSE/         # openSUSE-specific configs (myrlyn-sudo.conf, etc.)
    ├── qt6ct/            # Qt6 theming (wallust-generated colors)
    ├── sddm/             # SDDM login manager theme and config
    ├── wallust/          # Wallust config and templates
    ├── sway/             # Sway window manager config
    ├── waybar/           # Status bar config
    ├── rofi/             # Application launcher config
    ├── zsh/              # Shell configuration
    ├── zellij/           # Terminal multiplexer config
    ├── emacs/            # Emacs configuration
    ├── ghostty/          # Terminal config
    └── [20+ other apps]/ # All other dotfiles
```

**Important**:
- All application dotfiles are stored in `alatar_dots/` and deployed via symlinks using `alatar dots deploy`
- The `bin/` directory is deprecated - all new development uses `bin2/` (Tcl-based CLI)

## Theming System

### Wallust Integration

Wallust extracts colors from a wallpaper and generates themed configs for multiple applications. The flow:

1. User runs `pape.sh pick` or `pape.sh set <path>`
2. Wallpaper saved to `~/.config/wallpaper.png`
3. `wallust run` processes templates from `alatar_dots/wallust/templates/`
4. Generated configs deployed to target locations
5. Sway reloads to apply changes

### Themed Applications

Wallust generates configs for:
- SDDM (login screen colors and wallpaper)
- Sway (window borders, colors)
- Waybar (status bar colors)
- Rofi (launcher theme)
- Emacs (wallust-theme.el)
- Zellij (terminal colors)
- Qt6 apps via qt6ct (Myrlyn, YaST, etc.)
- KDE color scheme
- VS Code / VSCodium
- Zsh prompt
- TCL/Tk GUIs (help, nomicron)

**SDDM Login Screen**: The Alatar SDDM theme uses:
- Ancient font for UI text
- Wallust-generated colors from your wallpaper
- Your current wallpaper as the background
- Sway automatically selected as default session
- **Requires**: `sddm-qt6`, `sddm-greeter-qt6`, `qt6-declarative-imports` (included in prelude)
- See `alatar_dots/sddm/README.md` for installation instructions

**Qt6 Dark Mode**: Qt applications like Myrlyn use qt6ct for theming. The configuration:
- `alatar_dots/qt6ct/qt6ct.conf` - Main qt6ct config (Fusion style, wallust colors)
- `alatar_dots/qt6ct/colors/wallust.conf` - Wallust-generated color scheme
- `alatar_dots/openSUSE/myrlyn-sudo.conf` - Sets `QT_QPA_PLATFORMTHEME=qt6ct` for Myrlyn

### Template Location

Templates: `~/.alatar/alatar_dots/wallust/templates/`
Config: `~/.alatar/alatar_dots/wallust/wallust.toml`

Template variables include `{{background}}`, `{{foreground}}`, `{{color0}}`-`{{color15}}`, with filters like `lighten(0.1)`, `darken(0.1)`, `rgb`.

## Package Management

`packages.sh` abstracts logical package names to distro packages:

```bash
alatar packages install git neovim ripgrep
alatar packages list
alatar packages prelude  # Install core packages
```

Package specs can be:
- Plain packages: `"git"`
- Multiple packages: `"pkg1 pkg2 pkg3"`
- Patterns: `"@devel_basis"` (zypper patterns)
- Custom installers: `"!install_nvim"` (shell functions)

## GUI Framework

**This is a Tcl/Tk project** for managing a Linux system. All graphical system management tools are built with Tcl/Tk (recently migrated from Python for better performance and integration).

The shared theme library (`tools/theme.tcl`) loads wallust colors and applies them to TTK widgets, ensuring all GUI tools match the current system theme.

### Tcl/Tk Tools:
- **nomicron.tcl**: Power menu (shutdown/restart/logout/system settings/software launcher)
- **help.tcl**: Interactive help browser for manuals and keybindings
- **pathedit.tcl**: Visual PATH environment variable editor
- **focus-*.tcl**: Application window focus helpers (Spotify, etc.)

**Note**: The "Software" button in nomicron.tcl launches Myrlyn (openSUSE's graphical package manager) via the `myrlyn-sudo` wrapper.

All tools use the wallust theming system and follow consistent UI patterns defined in `tools/theme.tcl` and `tools/ui.tcl`.

## Script Dependency Map

Quick reference for installing script dependencies with `alatar packages`.

- `scripts/media.sh`: needs `playerctl` (Waybar media controls). Install: `alatar packages install waybar playerctl`.
- `scripts/pape.sh`: generates/picks wallpapers; installs its own needs but relies on `ImageMagick`, `swayimg`, `libnotify`, `sway`. Install explicitly if desired: `alatar packages install imagemagick image-viewer notify window-manager`.
- `bin/alatar_menu.sh`: requires `rofi` to show the menu (calls `scripts/pape.sh`). Install: `alatar packages install rofi`.
- `scripts/launch-cheatsheet.sh`, `scripts/launch-floating-command.sh`, `scripts/launch-floating-ghostty.sh`, `scripts/pin-alatar-shell.sh`: need `swaymsg` + `jq` plus any supported terminal (ghostty/foot/kitty/wezterm/xterm). Install: `alatar packages install window-manager jq`.
- `scripts/toggle-floating-terminal.sh`: toggles floating terminal; needs `swaymsg`, `jq`, and `zellij` (default command). Install: `alatar packages install window-manager jq zellij`.
- `scripts/toggle-floating-yazi.sh`: wraps the above launcher for `yazi`. Install: `alatar packages install window-manager jq yazi`.
- `scripts/vifmimg`: previews images in vifm; needs `kitty` (and KITTY_WINDOW_ID). Install: `alatar packages install kitty`.

## Waybar Notes

Config at `alatar_dots/sway/waybar/config.jsonc` expects: `waybar`, `playerctl` (media module), `brightnessctl` (backlight), `pavucontrol` (pulse menu), and `nm-connection-editor`. Install: `alatar packages install waybar playerctl backlight pavucontrol nm-connection-editor`.

## Deployment System

The `alatar dots deploy` command (in `bin2/dots.tcl`) symlinks dotfiles from `alatar_dots/` to their proper locations:

1. **Config files**: `alatar_dots/*` → `~/.config/*` (except special dirs: .git, zsh, newsboat, applications)
2. **Zsh files**: `alatar_dots/zsh/*` → `~/.zshenv`, `~/.zshrc`, `~/.zprofile`, `~/.zalias`, `~/.zsh_paths.sh`
3. **Desktop files**: `alatar_dots/applications/*.desktop` → `~/.local/share/applications/`
4. **Newsboat**: Special handling for config vs. data separation (XDG data dir)

### Desktop Files

Custom `.desktop` files are stored in `alatar_dots/applications/` and deployed to `~/.local/share/applications/`. This allows the Alatar system to:
- Override system desktop files (e.g., custom myrlyn launcher)
- Add custom application launchers
- Maintain desktop integration across system reinstalls

Example: `alatar_dots/applications/myrlyn.desktop` overrides the default Myrlyn launcher to use `myrlyn-sudo` for proper graphical authentication.

## Common Tasks

### Adding a new wallust-themed application

1. Create template in `alatar_dots/wallust/templates/`
2. Add mapping to `alatar_dots/wallust/wallust.toml`
3. Run `pape.sh set <current-wallpaper>` to regenerate

### Adding a new package

1. Edit `bin2/packages.tcl`
2. Add entry to the appropriate package list
3. Format varies - see existing entries for examples

### Adding a custom desktop file

1. Create `.desktop` file in `alatar_dots/applications/`
2. Run `alatar dots deploy` to symlink it
3. Desktop file will appear in application launchers (rofi, etc.)

### Installing SDDM theme

The Alatar SDDM theme provides a themed login screen with the Ancient font and your wallpaper.

**Quick Install:**
```bash
~/.alatar/bin2/alatar.tcl sddm install
sudo systemctl restart sddm
```

**Troubleshooting Read-Only File System:**
If you see "Read-only file system" errors, you're likely booted into a btrfs snapshot:

1. **Check if you're in a snapshot:**
   ```bash
   grep snapshot /proc/cmdline
   ```

2. **Fix option 1 - Reboot into main system (recommended):**
   - Reboot and select the default boot entry (not "Snapshot" entries)
   - Run the install again

3. **Fix option 2 - Remount as read-write (temporary):**
   ```bash
   sudo mount -o remount,rw /
   sudo ~/.alatar/bin2/alatar.tcl sddm install
   ```

The install command will:
- Install required Qt6 packages (sddm-qt6, sddm-greeter-qt6, qt6-declarative-imports)
- Install the Alatar theme to `/usr/share/sddm/themes/alatar/`
- Install SDDM configuration to `/etc/sddm.conf` (sets Wayland + Sway as defaults)
- Clear SDDM session state (removes cached session selection)
- Create wallpaper symlink
- Install Ancient font system-wide (from `~/.fonts/`)

**Theme Updates:**
When you change wallpapers with `pape.sh`, the SDDM theme colors are automatically updated. No manual intervention needed!

**Requirements:**
- Ancient Medium font in `~/.fonts/Ancient Medium.ttf`
- If missing, see `alatar_dots/fonts/README.md` for installation instructions

See `alatar_dots/sddm/README.md` for detailed instructions and manual installation steps.

### Creating a new TCL GUI tool

1. Source `tools/theme.tcl` for theming
2. Call `load_wallust_theme "help"` (or appropriate config)
3. Call `apply_ttk_theme` to style widgets
