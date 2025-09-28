#!/usr/bin/env bash

source ./packages.sh
source ./director.sh

function command_pkg {
    case "$1" in
        list) list_pkgs ;;
        install) install_pkgs "${@:2}" ;;
        *) echo "Not a valid pkg command" ;;
    esac
}

function command_cfg {
    case "$1" in
        deploy) echo "WIP" ;;
        *) echo "Not a valid cfg command" ;;
    esac
}

function command_dir {
    case "$1" in
        sync) sync_directory_structure ;;
        *) echo "Not a valid dir command" ;;
    esac
}

case "$1" in
    pkg) command_pkg "${@:2}" ;;
    cfg) command_cfg "${@:2}" ;;
    dir) command_dir "${@:2}" ;;
    *) echo "Not a valid command" ;;
esac
