#!/usr/bin/env bash

source $HOME/.alatar/bin/packages.sh
source $HOME/.alatar/bin/director.sh
source $HOME/.alatar/bin/dots.sh

is_help() {
  case "$1" in
    -h|--help|help|h) return 0 ;;
    *) return 1 ;;
  esac
}

help_main() {
  cat <<'EOF'
Usage: cmd <command> <subcommand> [options]

Commands:
  pkg|p    Package operations
  cfg|c    Config operations
  dir|d    Directory operations

Run: cmd <command> help           Show command help
     cmd <command> <sub> -h       Show subcommand help
EOF
}

help_pkg() {
  cat <<'EOF'
Usage: cmd pkg|p <subcommand> [options]

Subcommands:
  list|ls                 List available packages
  install|i <pkgs...>     Install one or more packages

Examples:
  cmd pkg list
  cmd p ls
  cmd pkg install ripgrep git
  cmd p i ripgrep git
EOF
}

help_pkg_list() {
  cat <<'EOF'
Usage: cmd pkg list

Options:
  -h, --help               Show this help

Description:
  Prints the available packages for the current distro.
EOF
}

help_pkg_install() {
  cat <<'EOF'
Usage: cmd pkg install <pkgs...>

Options:
  -h, --help               Show this help

Description:
  Installs the given packages on the current distro.

Examples:
  cmd pkg install ripgrep git
  cmd p i curl
EOF
}

help_cfg() {
  cat <<'EOF'
Usage: cmd cfg|c <subcommand> [options]

Subcommands:
  deploy|dep              Deploy configuration

Examples:
  cmd cfg deploy
  cmd c dep
EOF
}

help_cfg_deploy() {
  cat <<'EOF'
Usage: cmd cfg deploy

Options:
  -h, --help               Show this help

Description:
  Deploys configuration. Currently WIP.
EOF
}

help_dir() {
  cat <<'EOF'
Usage: cmd dir|d <subcommand> [options]

Subcommands:
  sync|s                  Sync directory structure

Examples:
  cmd dir sync
  cmd d s
EOF
}

help_dir_sync() {
  cat <<'EOF'
Usage: cmd dir sync

Options:
  -h, --help               Show this help

Description:
  Synchronizes the directory structure.
EOF
}

command_pkg() {
  sub="$1"
  shift || true
  if [ -z "$sub" ] || is_help "$sub"; then
    help_pkg
    return
  fi
  case "$sub" in
    list|ls)
      if is_help "$1"; then
        help_pkg_list
      else
        list_pkgs
      fi
      ;;
    install|i)
      if is_help "$1"; then
        help_pkg_install
      else
        install_pkgs "$@"
      fi
      ;;
    help|-h|--help|h)
      help_pkg
      ;;
    *)
      echo "Not a valid pkg command"
      ;;
  esac
}

command_cfg() {
  sub="$1"
  shift || true
  if [ -z "$sub" ] || is_help "$sub"; then
    help_cfg
    return
  fi
  case "$sub" in
    deploy|dep)
      if is_help "$1"; then
        help_cfg_deploy
      else
        deploy_dotfiles
      fi
      ;;
    help|-h|--help|h)
      help_cfg
      ;;
    *)
      echo "Not a valid cfg command"
      ;;
  esac
}

command_dir() {
  sub="$1"
  shift || true
  if [ -z "$sub" ] || is_help "$sub"; then
    help_dir
    return
  fi
  case "$sub" in
    sync|s)
      if is_help "$1"; then
        help_dir_sync
      else
        sync_directory_structure
      fi
      ;;
    help|-h|--help|h)
      help_dir
      ;;
    *)
      echo "Not a valid dir command"
      ;;
  esac
}

case "$1" in
  pkg|p) shift; command_pkg "$@" ;;
  cfg|c) shift; command_cfg "$@" ;;
  dir|d) shift; command_dir "$@" ;;
  help|-h|--help|h|"")
    help_main
    ;;
  *)
    echo "Not a valid command"
    ;;
esac

