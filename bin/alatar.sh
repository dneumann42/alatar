#!/usr/bin/env bash 

source $HOME/.alatar/bin/packages.sh
source $HOME/.alatar/bin/config.sh

show-help() {
    cat <<'EOF'
Usage: alatar <command> <sub-command> [options]

Commands:
	h,help					Show this help screen						
	p,package				Package operations
	c,config				Config operations
	d,director				Directory operations

Run: alatar <command> help			Show command help
     alatar <command> <sub-command> help       	Show command help
EOF
}

case "${1:-}" in
    p|package) shift; alatar-packages "$@" ;;
    c|config) shift; alatar-config "$@" ;;
    d|director) shift; echo "DIR WIP" ;;
    h|help) shift; show-help ;;
    *) show-help ;;
esac
