#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/.work/a52sxq-native"
CLEAN=false
VENDOR_URL="${A52SXQ_VENDOR_URL:-https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq/releases/download/A528BXXS6FXA1_BTU/A528BXXS6FXA1_vendor.zip}"
VENDOR_SHA256="${A52SXQ_VENDOR_SHA256:-dfc8acf78196d21287f137aa07e378cf9df0c6c55805fff1a81ec0c1dc0d3c43}"
KERNEL_URL="${A52SXQ_KERNEL_URL:-https://github.com/Mesa-Labs-Archive/proprietary_vendor_samsung_a52sxq/releases/download/A528BXXS6FXA1_BTU/A528BXXS6FXA1_kernel.tar}"
KERNEL_SHA256="${A52SXQ_KERNEL_SHA256:-9175331267f196a19f6d1cf9cc489150ed615396af0e8aeb51972be08336eb04}"

while (($#)); do
  case "$1" in
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --clean) CLEAN=true; shift ;;
    -h|--help)
      echo "Uso: fetch_a52sxq_native.sh [--out-dir DIR] [--clean]"; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

command -v curl >/dev/null || { echo "curl ausente" >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip ausente" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar ausente" >&2; exit 1; }
command -v lz4 >/dev/null || { echo "lz4 ausente" >&2; exit 1; }

if "$CLEAN"; then rm -rf "$OUT_DIR"; fi
mkdir -p "$OUT_DIR/downloads" "$OUT_DIR/extracted"
VENDOR_ZIP="$OUT_DIR/downloads/a52sxq-vendor.zip"
KERNEL_TAR="$OUT_DIR/downloads/a52sxq-kernel.tar"

fetch() {
  local url="$1" out="$2" expected="$3"
  if [[ ! -s "$out" ]]; then
    curl -L --fail --retry 5 --retry-delay 3 --continue-at - -o "$out" "$url"
  fi
  printf '%s  %s\n' "$expected" "$out" | sha256sum -c -
}

fetch "$VENDOR_URL" "$VENDOR_ZIP" "$VENDOR_SHA256"
fetch "$KERNEL_URL" "$KERNEL_TAR" "$KERNEL_SHA256"

unzip -tq "$VENDOR_ZIP"
unzip -p "$VENDOR_ZIP" vendor.img > "$OUT_DIR/vendor.img"
rm -rf "$OUT_DIR/extracted/kernel"
mkdir -p "$OUT_DIR/extracted/kernel"
tar -xf "$KERNEL_TAR" -C "$OUT_DIR/extracted/kernel"
for name in boot dtbo vbmeta vendor_boot; do
  lz4 -d -f "$OUT_DIR/extracted/kernel/${name}.img.lz4" "$OUT_DIR/${name}.img"
done

cat > "$OUT_DIR/source.properties" <<EOF
vendor_url=$VENDOR_URL
vendor_sha256=$VENDOR_SHA256
kernel_url=$KERNEL_URL
kernel_sha256=$KERNEL_SHA256
vendor_release=A528BXXS6FXA1_BTU
native_target=a52sxq
native_model=SM-A528B
native_platform=sm7325
EOF
sha256sum "$OUT_DIR"/*.img >> "$OUT_DIR/source.properties"
echo "Entradas nativas do A52s prontas em $OUT_DIR"
