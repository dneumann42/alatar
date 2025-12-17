#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.alatar/alatar_dots"
DOTFILES_REPO="git@github.com:dneumann42/alatar_dots.git"

show-config-help() {
    cat <<'EOF'
Usage: alatar config <sub-command>

Sub-Commands:
	d,deploy	Deploys dot files by symlinking into $XDG_CONFIG_HOME
	s,sync		Pull from origin of all remote config repos
EOF
}

deploy_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
	git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    local dots_dir="$DOTFILES_DIR"
    local config_dir="$HOME/.config"

    mkdir -p "$config_dir"
    
    ln -sfn "$dots_dir/zsh/zshenv"    "$HOME/.zshenv"
    ln -sfn "$dots_dir/zsh/zshrc"     "$HOME/.zshrc"
    ln -sfn "$dots_dir/zsh/zprofile"  "$HOME/.zprofile"
    ln -sfn "$dots_dir/zsh/zalias"    "$HOME/.zalias"

    for path in "$dots_dir"/*; do
        local name
        name="$(basename "$path")"

        [[ "$name" == ".git" || "$name" == "zsh" ]] && continue
        [[ -d "$path" ]] || continue

        dest="$config_dir/$name"

        # Prevent ln from nesting into an existing directory
        if [[ -d "$dest" && ! -L "$dest" ]]; then
            rm -rf -- "$dest"
        fi

        ln -sfnT -- "$path" "$dest"
        echo "Linked $path -> $dest"
    done
}

function alatar-config {
  sub="${1:-}"
  shift || true
  if [ -z "$sub" ] || is_help "$sub"; then
    show-config-help
    return
  fi
  case "$sub" in
      d|deploy) deploy_dotfiles ;;
      s|sync) echo "SYNC IS WIP" ;;
      *) echo "Not a valid config command" ;;
  esac
}
