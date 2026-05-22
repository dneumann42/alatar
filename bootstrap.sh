#!/usr/bin/env bash

set -euo pipefail

ensure_alatar_env() {
  local file="$HOME/.alatar_env"
  local begin="# >>> alatar managed env >>>"
  local end="# <<< alatar managed env <<<"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  local block
  block="$(cat <<'EOF'
# >>> alatar managed env >>>
if [ -z "${ALATAR_HOME+x}" ]; then
  export ALATAR_HOME="$HOME/.alatar"
fi
export PATH="$ALATAR_HOME/vendor/chicken/bin:$PATH"
# <<< alatar managed env <<<
EOF
)"

  if grep -qF "$begin" "$file"; then
    awk -v begin="$begin" -v end="$end" -v block="$block" '
      $0 == begin {
        print block
        in_block = 1
        next
      }

      $0 == end {
        in_block = 0
        next
      }

      !in_block {
        print
      }
    ' "$file" > "$file.tmp"

    mv "$file.tmp" "$file"
  else
    {
      printf '\n%s\n' "$block"
    } >> "$file"
  fi
}  

ensure_alatar_env

if [[ -f "$HOME/.alatar_env" ]]; then
    source "$HOME/.alatar_env"
fi

ensure_arch_deps() {
  missing=""

  for pkg in base-devel tar curl; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      missing="$missing $pkg"
    fi
  done

  if [ -n "$missing" ]; then
    sudo pacman -S --needed $missing
  fi
}

ensure_arch_deps

# TODO: we should manage versions of chicken
if [[ ! -f "$ALATAR_HOME/vendor/chicken.tar.gz" ]]; then
    mkdir -p "$ALATAR_HOME/vendor/"
    wget "https://code.call-cc.org/releases/5.4.0/chicken-5.4.0.tar.gz" -O "$ALATAR_HOME/vendor/chicken.tar.gz"
fi

[[ ! -f "$ALATAR_HOME/vendor/chicken.tar.gz" ]] && exit 1;

if [[ ! -d "$ALATAR_HOME/vendor/chicken" ]]; then
    mkdir -p "$ALATAR_HOME/vendor/chicken"
    tar -xf "$ALATAR_HOME/vendor/chicken.tar.gz" -C "$ALATAR_HOME/vendor/chicken" --strip-components=1
fi

[[ ! -d "$ALATAR_HOME/vendor/chicken" ]] && exit 1;

pushd "$ALATAR_HOME/vendor/chicken" >>/dev/null
make PLATFORM=linux PREFIX="$ALATAR_HOME/vendor/chicken"
make PLATFORM=linux PREFIX="$ALATAR_HOME/vendor/chicken" install
popd >>/dev/null
