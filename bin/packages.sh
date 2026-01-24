#!/usr/bin/env bash

set -euo pipefail

declare -A pkg_suse=(
  [build-tools]="@devel_basis meson clang-tools|Base development toolchain"
  [backlight]="brightnessctl|Backlight control utility"
  [bat]="bat|Cat replacement with syntax highlighting"
  [ripgrep]="ripgrep|Fast text search tool"
  [git]="git|Git version control"
  [curl]="curl|HTTP client"
  [fltk]="fltk-devel|FLTK GUI toolkit"
  [jq]="jq|Command-line JSON processor"
  [rust]="rustup|Rust toolchain (via rustup)"
  [neovim]="!install_nvim|Neovim editor (managed via bob)"
  [nim]="!install_nim|Nim programming language"
  [notify]="libnotify-tools|Notifications"
  [github-cli]="gh|Github cli tool"
  [playerctl]="playerctl|MPRIS media controller"
  [pavucontrol]="pavucontrol|PulseAudio volume control"
  [rofi]="rofi|Rofi application launcher"
  [kitty]="kitty|Kitty GPU terminal emulator"
  [zellij]="zellij|Terminal workbspace/tmux alternative"
  [yazi]="yazi|TUI file manager"
  [tldr]="tlrc|Simplified man pages (tlrc)"
  [window-manager]="sway|Wayland window manager"
  [waybar]="waybar|Wayland status bar"
  [imagemagick]="ImageMagick|Image processing utilities"
  [qutebrowser]="qutebrowser|Keyboard-driven web browser"
  [mpv]="mpv|Media player with YouTube support via yt-dlp"
  [yt-dlp]="yt-dlp|YouTube downloader backend for mpv"
  [image-viewer]="swayimg|Wayland image viewer"
  [pdf-viewer]="zathura zathura-plugin-pdf-mupdf|Vim PDF viewer"
  [nm-connection-editor]="NetworkManager-connection-editor|NetworkManager connection editor GUI"
  [rss]="newsboat|RSS feed reader"
  [python]="uv|Python development tool"
  [wallust]="!ensure_wallust|A theme tool"
  [lsd]="lsd|A modern ls"
  [qt6ct]="qt6ct|Qt6 configuration tool for non-KDE environments"
  [tcl-tk]="tcl tclx tk|TCL scripting language with Tk GUI toolkit"
  [fonts]="google-noto-coloremoji-fonts intlfonts|Emoji font for GUI applications"
  [cockpit]="cockpit cockpit-networkmanager cockpit-storaged cockpit-packagekit !enable_cockpit|Web-based system management"
)

ensure_rustup_default() {
  command -v rustup >/dev/null 2>&1 || return 0
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    rustup default stable
  fi
}

pkg_spec() {
  local key="$1"
  local v="${pkg_suse[$key]:-}"
  [[ -n "$v" ]] || { echo "$key"; return; }
  echo "${v%%|*}"
}

pkg_doc() {
  local key="$1"
  local v="${pkg_suse[$key]:-}"
  [[ -n "$v" ]] || { echo ""; return; }
  [[ "$v" == *"|"* ]] && echo "${v#*|}" || echo ""
}

pkg() {
  local key="$1"
  echo "$(pkg_spec "$key")"
}

list_pkgs() {
  echo "openSUSE packages:"
  for k in "${!pkg_suse[@]}"; do
    printf "  %-15s -> %s\n" "$k" "$(pkg_spec "$k")"
  done
}

install_pkgs() {
  local -a pkgs=()
  local -a patterns=()
  local -a cmds=()

  for key in "$@"; do
    local spec
    spec="$(pkg "$key")"   # may be: "@pattern", "!cmd", or "pkg1 pkg2 ..."

    # Split spec into words so one keyword can map to multiple packages
    local -a items=()
    read -r -a items <<< "$spec"

    local name
    for name in "${items[@]}"; do
      if [[ $name == @* ]]; then
        patterns+=("${name#@}")
      elif [[ $name == !* ]]; then
        cmds+=("${name#!}")
      else
        pkgs+=("$name")
      fi
    done
  done

  if ((${#patterns[@]})); then
    sudo zypper --non-interactive install -t pattern "${patterns[@]}"
  fi

  if ((${#pkgs[@]})); then
    local -a missing_pkgs=()

    for pkg in "${pkgs[@]}"; do
      if ! rpm -q "$pkg" >/dev/null 2>&1; then
        missing_pkgs+=("$pkg")
      fi
    done

    if ((${#missing_pkgs[@]})); then
      sudo zypper --non-interactive install "${missing_pkgs[@]}"
    fi
  fi

  if ((${#cmds[@]})); then
    "${cmds[@]}"
  fi
}

install_nvim() {
    install_pkgs rust
    ensure_rustup_default

    if command -v bob >/dev/null 2>&1; then
	:
    else
	cargo install bob-nvim
    fi

    sleep 0.1
    bob use nightly
}

ensure_wallust() {
    install_pkgs rust
    ensure_rustup_default
    if command -v wallust >/dev/null 2>&1; then
	:
    else
	cargo install wallust
    fi
}

install_nim() {
	if [ $(command -v grabnim >/dev/null) ]; then
		mkdir -p $HOME/.cache/
		curl https://codeberg.org/janAkali/grabnim/raw/branch/master/misc/install.sh > $HOME/.cache/install-grabnim.sh
		sh $HOME/.cache/install-grabnim.sh
		grabnim
	fi
}

enable_cockpit() {
	sudo systemctl enable --now cockpit.socket
	echo "Cockpit enabled at https://localhost:9090"
}

show-packages-help() {
    cat <<'EOF'
Usage: alatar packages <sub-command> [args...]

Sub-Commands:
        l,list          List package names and their distro mappings
        i,install       Install one or more logical packages
        p,prelude       Install the core/prelude package set

Packages:
EOF
    for k in $(printf "%s\n" "${!pkg_suse[@]}" | LC_ALL=C sort); do
        printf "        %-15s %s\n" "$k" "$(pkg_doc "$k")"
    done
    cat <<'EOF'

Examples:
        alatar packages list
        alatar packages install git neovim ripgrep
        alatar packages prelude
EOF
}

install_prelude() {
  install_pkgs build-tools git curl ripgrep lsd qt6ct tcl-tk emoji-fonts cockpit
}

is_help() {
  case "$1" in
    help|h) return 0 ;;
    *) return 1 ;;
  esac
}

alatar-packages() {
  sub="${1:-}"
  shift || true
  if [ -z "$sub" ] || is_help "$sub"; then
    show-packages-help
    return
  fi
  case "$sub" in
      list|ls) list_pkgs ;;
      install|i) install_pkgs "$@" ;;
      install-all) install_pkgs "${!pkg_suse[@]}" ;;
      prelude) install_prelude ;;
      *) echo "Not a valid pkg command" ;;
  esac
}
