#!/usr/bin/env bash

# TODO:
# allow replacing the URL with a custom repo

## Manages dotfiles

if [ ! -d ./alatar_dots/ ]; then
    git clone git@github.com:dneumann42/alatar_dots.git $HOME/.alatar/alatar_dots
else
    pushd $HOME/.alatar/alatar_dots >/dev/null
    git stash
    git pull
    git stash pop
    popd >/dev/null
fi

function deploy_dotfiles {
    echo "WIP"
}
