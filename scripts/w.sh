#!/usr/bin/env bash

FILE=$(wikid --list | fzf)
echo $(wikid --get-path:$FILE)

