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

        [[ "$name" == ".git" || "$name" == "zsh" || "$name" == "newsboat" || "$name" == "applications" ]] && continue
        [[ -d "$path" ]] || continue

        local dest
        dest="$config_dir/$name"

        # Prevent ln from nesting into an existing directory
        if [[ -d "$dest" && ! -L "$dest" ]]; then
            rm -rf -- "$dest"
        fi

        ln -sfnT -- "$path" "$dest"
        echo "Linked $path -> $dest"
    done

    # Newsboat: keep config under version control; data lives in XDG data dir (no ~/.newsboat)
    local newsboat_repo_dir="$dots_dir/newsboat"
    if [[ -d "$newsboat_repo_dir" ]]; then
        local newsboat_config_dir="$config_dir/newsboat"
        local newsboat_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/newsboat"
        local newsboat_cache_dest="$newsboat_data_dir/cache.db"

        mkdir -p "$newsboat_config_dir" "$newsboat_data_dir"

        local newsboat_legacy_dir="$HOME/.newsboat"
        if [[ -d "$newsboat_legacy_dir" ]]; then
            if [[ -f "$newsboat_legacy_dir/cache.db" && ! -e "$newsboat_cache_dest" ]]; then
                mv "$newsboat_legacy_dir/cache.db" "$newsboat_cache_dest"
                echo "Moved legacy newsboat cache to $newsboat_cache_dest"
            fi

            if [[ -f "$newsboat_legacy_dir/history.cmdline" && ! -e "$newsboat_config_dir/history.cmdline" ]]; then
                mv "$newsboat_legacy_dir/history.cmdline" "$newsboat_config_dir/history.cmdline"
                echo "Moved legacy newsboat history to $newsboat_config_dir/history.cmdline"
            fi

            rm -rf -- "$newsboat_legacy_dir"
            echo "Removed legacy ~/.newsboat directory"
        fi

        ln -sfn "$newsboat_repo_dir/config" "$newsboat_config_dir/config"
        ln -sfn "$newsboat_repo_dir/urls" "$newsboat_config_dir/urls"
        echo "Linked newsboat config into $newsboat_config_dir"
    fi

    # Desktop files: symlink to ~/.local/share/applications
    local apps_repo_dir="$dots_dir/applications"
    if [[ -d "$apps_repo_dir" ]]; then
        local apps_dest_dir="$HOME/.local/share/applications"
        mkdir -p "$apps_dest_dir"

        for desktop_file in "$apps_repo_dir"/*.desktop; do
            [[ -f "$desktop_file" ]] || continue
            local filename
            filename="$(basename "$desktop_file")"
            ln -sfn "$desktop_file" "$apps_dest_dir/$filename"
            echo "Linked $desktop_file -> $apps_dest_dir/$filename"
        done
    fi
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
