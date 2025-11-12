#!/usr/bin/env bash

# Declare a mapping between common package names, and their platforms package names
# '@' means its a group package, '@!' means its an executable command

source $HOME/.alatar/bin/distros.sh

declare -A pkg_arch=(
    [build-tools]=base-devel
    [ripgrep]=ripgrep
    [git]=git
    [curl]=curl
    [rust]=rustup
    [neovim]="!install_nvim"
    [window-manager]=sway
    [imagemagick]=ImageMagick
    [qutebrowser]=qutebrowser
)

declare -A pkg_fedora=(
    [build-tools]="@development-tools"
    [ripgrep]=ripgrep
    [git]=git
    [curl]=curl
    [rust]=rustup
    [neovim]="!install_nvim"
    [window-manager]=sway
    [imagemagick]=ImageMagick
    [qutebrowser]=qutebrowser
)

pkg() {
    local key="$1"
    case "$DISTRO" in
        arch)   echo "${pkg_arch[$key]:-$key}" ;;
        fedora) echo "${pkg_fedora[$key]:-$key}" ;;
    esac
}

list_pkgs() {
  case "$DISTRO" in
    arch)
      echo "Arch packages:"
      for k in "${!pkg_arch[@]}"; do
        printf "  %-15s -> %s\n" "$k" "${pkg_arch[$k]}"
      done
      ;;
    fedora)
      echo "Fedora packages:"
      for k in "${!pkg_fedora[@]}"; do
        printf "  %-15s -> %s\n" "$k" "${pkg_fedora[$k]}"
      done
      ;;
    *)
      echo "Unknown DISTRO: $DISTRO" >&2
      return 1
      ;;
  esac
}

install_pkgs() {
  local -a pkgs=()
  local -a groups=()
  local -a cmds=()

  for key in "$@"; do
    local name
    name="$(pkg "$key")"
    if [[ $name == @* ]]; then
      groups+=("${name#@}")
    elif [[ $name == !* ]]; then
        cmds+=("${name#!}")
    else
      pkgs+=("$name")
    fi
  done

  if [[ "$DISTRO" == arch ]]; then
    if ((${#pkgs[@]})); then sudo pacman -Sy --needed --noconfirm "${pkgs[@]}"; fi
    if ((${#groups[@]})); then sudo pacman -Sy --needed --noconfirm "${groups[@]}"; fi
    if ((${#cmds[@]})); then "${cmds[@]}"; fi
  else
    if ((${#groups[@]})); then sudo dnf group install -y "${groups[@]}"; fi
    if ((${#pkgs[@]})); then sudo dnf install -y "${pkgs[@]}"; fi
    if ((${#cmds[@]})); then "${cmds[@]}"; fi
  fi
}

function install_nvim {
    if [[ "$DISTRO" == arch ]]; then
        sudo pacman -Sy --needed --noconfirm bob
    else
        install_pkgs rustup
        cargo install bob-nvim
    fi
    sleep 0.1
    bob use nightly
}

# All of the most important packages get installed here
function install_prelude {
    install_pkgs build-tools git curl ripgrep
}
