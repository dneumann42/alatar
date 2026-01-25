# Alatar - TCL-Based Linux Management System

Alatar is a TCL-based system management tool for configuring and maintaining Arch Linux desktop environments with Sway/Wayland.

## Project Overview

Alatar automates the setup and management of a modern Linux desktop environment, focusing on:
- Wayland/Sway compositor configuration
- System-wide dependency management
- Dotfile management via git repositories
- Service management (systemd)
- Desktop environment setup

## Architecture

The project is structured as a modular TCL application with a main entry point and specialized library modules:

### Main Entry Point
- `lib/alatar.tcl` - Main script that orchestrates all modules

### Core Modules

- `lib/base.tcl` - Foundational utilities (file I/O, logging, service management)
- `lib/config.tcl` - Configuration file management
- `lib/dependencies.tcl` - Package installation via pacman and flatpak
- `lib/desktop.tcl` - Desktop environment setup (Sway, ly display manager)
- `lib/dots.tcl` - Dotfile management (cloning repositories)
- `lib/ssh.tcl` - SSH configuration

### Directory Structure

```
~/.alatar/
├── lib/              # Core TCL libraries
├── alatar_dots/      # Cloned dotfiles repository
└── .config/alatar/   # User configuration
```

## Key Features

### Dependency Management
The dependency system (`lib/dependencies.tcl`) manages packages through:
- **Pacman** for Arch packages
- **Flatpak** for sandboxed applications
- Dependency groups (base, desktop, flatpak)
- Automatic installation checking
- Support for dependency chains

### Desktop Environment
Configures a modern Wayland-based desktop:
- **Sway** - i3-compatible Wayland compositor
- **ly** - TUI display manager
- **Waybar** - Status bar
- **Rofi** - Application launcher
- **Ghostty** - Terminal emulator
- Various utilities (brightnessctl, mako, etc.)

### Dotfile Management (In Progress)
Current implementation:
- Clones dotfile repository from configured URL
- Stores in `~/.alatar/alatar_dots/`

**Not yet implemented:**
- Symlinking dotfiles to appropriate locations in `~/.config/`
- Selective dotfile installation
- Dotfile conflict resolution
- Backup of existing configurations

### Service Management
Provides utilities for systemd service control:
- Check if services are enabled/active
- Enable and start services
- Combined operations (ensureService)

## Configuration

Configuration is managed through `lib/config.tcl` with settings stored in `~/.config/alatar/`. Key configuration options include:
- Dotfiles repository URL
- Alatar home directory
- User-specific preferences

## Technologies

- **TCL/Tk** - Core scripting language (Tk for future GUI features)
- **Arch Linux** - Target distribution (pacman package manager)
- **Sway** - Wayland compositor
- **Wayland** - Display server protocol
- **systemd** - Service management
- **Git** - Dotfile repository management

## Usage

The system is designed to be run via the main script:
```bash
export ALATAR_HOME=~/.alatar
~/.alatar/lib/alatar.tcl
```

## Future Development

Planned features for dotfile management:
1. Intelligent symlinking of configs to `~/.config/`
2. Selective installation of dotfile groups
3. Conflict detection and resolution
4. Backup mechanism for existing configurations
5. Dotfile template support
6. Per-machine configuration variants

## Design Philosophy

- **Modularity** - Separate concerns into focused modules
- **Idempotency** - Operations can be run multiple times safely
- **Declarative** - Define desired state, let the system converge
- **Minimal dependencies** - Use built-in TCL features where possible
- **Progressive enhancement** - Start with working basics, add features incrementally
