#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR"
DRY_RUN=false

while (($#)); do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) echo "Uso: patch.sh [--source-root DIR] [--dry-run]"; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

PATCH_ROOT="$SOURCE_ROOT/patches"
[[ -d "$PATCH_ROOT" ]] || { echo "Diretório de patches ausente: $PATCH_ROOT" >&2; exit 1; }
mkdir -p "$SOURCE_ROOT/out/patches"
REPORT="$SOURCE_ROOT/out/patches/applied.tsv"
printf 'layer\tpatch\tstatus\n' > "$REPORT"

shopt -s nullglob
for layer_dir in "$PATCH_ROOT"/*; do
  [[ -d "$layer_dir" ]] || continue
  layer="$(basename "$layer_dir")"
  for patch in "$layer_dir"/*.patch; do
    if "$DRY_RUN"; then
      git -C "$SOURCE_ROOT" apply --check "$patch"
      status=check-only
    else
      git -C "$SOURCE_ROOT" apply --index "$patch"
      status=applied
    fi
    printf '%s\t%s\t%s\n' "$layer" "${patch#"$SOURCE_ROOT"/}" "$status" >> "$REPORT"
  done
done

echo "Patch pass concluído; relatório: $REPORT"
