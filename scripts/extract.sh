#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR=""
OUTPUT_DIR="$ROOT_DIR/proprietary/a52sxq"

while (($#)); do
  case "$1" in
    --input-dir) INPUT_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: extract.sh --input-dir DIR [--output-dir DIR]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$INPUT_DIR" ]] || { echo "Informe --input-dir com um dump autorizado." >&2; exit 2; }
[[ -d "$INPUT_DIR" ]] || { echo "Diretório de entrada inexistente: $INPUT_DIR" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"

# Copy only regular files, preserving relative paths. Symlinks are recorded but not followed.
MANIFEST="$OUTPUT_DIR/proprietary-manifest.txt"
: > "$MANIFEST"
while IFS= read -r -d '' file; do
  rel="${file#"$INPUT_DIR"/}"
  dest="$OUTPUT_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -a --no-preserve=ownership "$file" "$dest"
  sha="$(sha256sum "$dest" | awk '{print $1}')"
  size="$(stat -c '%s' "$dest")"
  printf '%s\t%s\t%s\n' "$sha" "$size" "$rel" >> "$MANIFEST"
done < <(find "$INPUT_DIR" -type f -print0 | sort -z)

find "$INPUT_DIR" -type l -printf 'SYMLINK\t%p\t%l\n' | sort >> "$MANIFEST" || true
printf 'source_dir=%s\n' "$INPUT_DIR" > "$OUTPUT_DIR/extraction.properties"
printf 'extracted_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUTPUT_DIR/extraction.properties"
printf 'files=%s\n' "$(grep -cve '^SYMLINK' "$MANIFEST" || true)" >> "$OUTPUT_DIR/extraction.properties"
echo "Extração concluída: $OUTPUT_DIR"
