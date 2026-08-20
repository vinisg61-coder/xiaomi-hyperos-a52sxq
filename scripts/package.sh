#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="$ROOT_DIR/out"
OUTPUT_DIR="$ROOT_DIR/dist"
FORCE_FLASHABLE=false

while (($#)); do
  case "$1" in
    --input-dir) INPUT_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --force-flashable) FORCE_FLASHABLE=true; shift ;;
    -h|--help)
      echo "Uso: package.sh [--input-dir DIR] [--output-dir DIR] [--force-flashable]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$INPUT_DIR" ]] || { echo "Diretório de entrada inexistente: $INPUT_DIR" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"

if [[ -f "$INPUT_DIR/manifest/build.properties" ]]; then
  # shellcheck disable=SC1091
  source <(sed -E 's/[^A-Za-z0-9_].*=.*/&/' "$INPUT_DIR/manifest/build.properties" | grep -E '^(build_id|target_device|boot_confirmed)=') || true
fi

image_count=$(find "$INPUT_DIR" -maxdepth 2 -type f -name '*.img' | wc -l | tr -d ' ')
if (( image_count > 0 )); then
  name="a52sxq-test-images-${GITHUB_RUN_ID:-local}"
  if "$FORCE_FLASHABLE"; then
    [[ -f "$INPUT_DIR/manifest/build.properties" ]] || { echo "manifest de build ausente" >&2; exit 2; }
    grep -q '^boot_confirmed=false$' "$INPUT_DIR/manifest/build.properties" && {
      echo "Não é permitido marcar pacote flashable com boot_confirmed=false." >&2
      exit 3
    }
  fi
else
  name="a52sxq-bringup-bundle-${GITHUB_RUN_ID:-local}"
fi

archive="$OUTPUT_DIR/${name}.tar.gz"
tar -czf "$archive" -C "$INPUT_DIR" .
sha256sum "$archive" > "$archive.sha256"
printf 'artifact=%s\nkind=%s\nimages=%s\n' "$archive" "$([[ $image_count -gt 0 ]] && echo test-images || echo bringup-bundle)" "$image_count" > "$OUTPUT_DIR/package.properties"
echo "Pacote criado: $archive"
