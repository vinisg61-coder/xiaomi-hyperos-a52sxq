#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --check-only) CHECK_ONLY=true ;;
    -h|--help)
      echo "Uso: $0 [--check-only]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

required=(bash git curl sha256sum tar unzip python3)
optional=(jq repo java)
missing=()
for cmd in "${required[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if (( ${#missing[@]} > 0 )); then
  echo "Dependências obrigatórias ausentes: ${missing[*]}" >&2
  if "$CHECK_ONLY"; then
    exit 1
  fi
  if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bash coreutils curl git jq openjdk-17-jdk python3 tar unzip
  else
    echo "Não há gerenciador apt/sudo disponível para instalar dependências." >&2
    exit 1
  fi
fi

if [[ -f "$ROOT_DIR/config/project.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/config/project.env"
fi

for cmd in "${optional[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'optional %-8s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'optional %-8s missing\n' "$cmd"
  fi
done

printf 'target=%s\n' "${TARGET_DEVICE:-unknown}"
printf 'platform=%s\n' "${TARGET_PLATFORM:-unknown}"
printf 'android=%s\n' "${TARGET_ANDROID_VERSION:-unknown}"
printf 'variant=%s\n' "${TARGET_BUILD_VARIANT:-unknown}"
printf 'setup=ok\n'
