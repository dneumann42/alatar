#!/usr/bin/env bash

if command -v dnf >/dev/null 2>&1; then
  export DISTRO="fedora"
else
  export DISTRO="arch"
fi

