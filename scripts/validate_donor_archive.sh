#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR"
REPORT_DIR="$ROOT_DIR/out/donor-validate"
ARCHIVE=""

while (($#)); do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --archive) ARCHIVE="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: validate_donor_archive.sh --archive FILE [--report-dir DIR]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$ARCHIVE" ]]; then
  ARCHIVE="$SOURCE_ROOT/.work/hyperos-donor.zip"
fi
[[ -f "$ARCHIVE" ]] || { echo "Archive donor ausente: $ARCHIVE" >&2; exit 3; }
mkdir -p "$REPORT_DIR"

sha256sum "$ARCHIVE" | tee "$REPORT_DIR/archive.sha256"
stat -c 'name=%n\nsize=%s\nmtime=%y' "$ARCHIVE" > "$REPORT_DIR/archive.stat"
unzip -tq "$ARCHIVE"
unzip -l "$ARCHIVE" > "$REPORT_DIR/archive.list"

required=(boot.img dtbo.img super.img.zst)
for entry in "${required[@]}"; do
  if ! unzip -Z1 "$ARCHIVE" | grep -Fxq "$entry"; then
    echo "Artefato obrigatório ausente no donor: $entry" >&2
    exit 4
  fi
done

cat > "$REPORT_DIR/README.txt" <<'EOF'
Donor archive validated as data only.
This report does not certify compatibility with Samsung a52sxq and does not produce a flashable ROM.
The donor boot.img, dtbo.img and super.img.zst belong to the Xiaomi sweet/Redmi Note 10 Pro port and must not be flashed on a52sxq.
EOF
printf 'validated=true\narchive=%s\nrequired=boot.img,dtbo.img,super.img.zst\nboot_confirmed=false\nflashable=false\n' "$ARCHIVE" > "$REPORT_DIR/result.properties"
echo "Donor archive validado: $ARCHIVE"
