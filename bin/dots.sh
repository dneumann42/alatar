#!/usr/bin/env bash

# TODO:
# allow replacing the URL with a custom repo

## Manages dotfiles

DOTS_DIR="$HOME/.alatar/alatar_dots"

if [ ! -d "$DOTS_DIR" ]; then
    git clone git@github.com:dneumann42/alatar_dots.git $HOME/.alatar/alatar_dots
else
    pushd $HOME/.alatar/alatar_dots >/dev/null
    git stash
    git pull
    git stash pop
    popd >/dev/null
fi

function deploy_dotfiles {
    local dots_dir="$DOTS_DIR"
    local config_dir="$HOME/.config"

    mkdir -p "$config_dir"

    ln -sfn "$config_dir/zsh/zshenv" "$HOME/.zshenv" 
    ln -sfn "$config_dir/zsh/zshrc" "$HOME/.zshrc" 
    ln -sfn "$config_dir/zsh/zprofile" "$HOME/.zprofile" 
    ln -sfn "$config_dir/zsh/zalias" "$HOME/.zalias" 

    for path in "$dots_dir"/*; do
        local name
        name="$(basename "$path")"

        if [[ "$name" = ".git" ]] || [[ "$name" = "zsh" ]]; then
            continue
        fi

        if [ -d "$path" ]; then
            ln -sfn "$path" "$config_dir/$name"
            echo "Linked $path -> $config_dir/$name"
        fi
    done
}
