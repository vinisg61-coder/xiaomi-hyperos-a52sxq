#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR"
OUT_DIR="$ROOT_DIR/out/port"
DONOR_ARCHIVE="$ROOT_DIR/.work/hyperos-donor.zip"
NATIVE_DIR="$ROOT_DIR/.work/a52sxq-native"

while (($#)); do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --donor-archive) DONOR_ARCHIVE="$2"; shift 2 ;;
    --native-dir) NATIVE_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: port_stage.sh --donor-archive ZIP --native-dir DIR [--out-dir DIR]"; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$DONOR_ARCHIVE" ]] || { echo "Donor archive ausente: $DONOR_ARCHIVE" >&2; exit 1; }
[[ -d "$NATIVE_DIR" ]] || { echo "Entradas nativas ausentes: $NATIVE_DIR" >&2; exit 1; }
for name in boot dtbo vbmeta vendor_boot vendor; do
  [[ -s "$NATIVE_DIR/$name.img" ]] || { echo "Imagem nativa ausente: $NATIVE_DIR/$name.img" >&2; exit 1; }
done
command -v unzip >/dev/null || { echo "unzip ausente" >&2; exit 1; }
command -v zstd >/dev/null || { echo "zstd ausente" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 ausente" >&2; exit 1; }

LPUNPACK="$SOURCE_ROOT/tools/lpunpack.py"
[[ -f "$LPUNPACK" ]] || { echo "tools/lpunpack.py ausente" >&2; exit 1; }
mkdir -p "$OUT_DIR/donor" "$OUT_DIR/native" "$OUT_DIR/manifest" "$OUT_DIR/logs"
rm -rf "$OUT_DIR/donor/logical" "$OUT_DIR/donor/super.img"
mkdir -p "$OUT_DIR/donor/logical"

unzip -tq "$DONOR_ARCHIVE"
unzip -p "$DONOR_ARCHIVE" super.img.zst > "$OUT_DIR/donor/super.img.zst"
zstd -q -d -f "$OUT_DIR/donor/super.img.zst" -o "$OUT_DIR/donor/super.img"
python3 "$LPUNPACK" --info --format json "$OUT_DIR/donor/super.img" > "$OUT_DIR/donor/logical/metadata.json"
python3 "$LPUNPACK" "$OUT_DIR/donor/super.img" "$OUT_DIR/donor/logical"

for name in boot dtbo vbmeta vendor_boot vendor; do
  cp -f "$NATIVE_DIR/$name.img" "$OUT_DIR/native/$name.img"
done
cp -f "$NATIVE_DIR/source.properties" "$OUT_DIR/native/source.properties" 2>/dev/null || true

cat > "$OUT_DIR/manifest/port.properties" <<EOF
port_kind=hybrid-userspace-native-hardware
port_target=a52sxq
port_model=SM-A528B
port_platform=sm7325
port_android=15
port_hyperos=2.0.215
userspace_source=CraftyOs_China_HOTFIX.zip
userspace_source_architecture=donor_prebuilt_super
native_source_release=A528BXXS6FXA1_BTU
native_boot_included=true
native_dtbo_included=true
native_vendor_boot_included=true
native_vendor_included=true
boot_confirmed=false
flashable=false
hardware_port_complete=false
EOF
sha256sum "$DONOR_ARCHIVE" "$OUT_DIR/donor/super.img.zst" "$OUT_DIR/donor/super.img" "$OUT_DIR"/donor/logical/*.img "$OUT_DIR"/native/*.img > "$OUT_DIR/manifest/hashes.sha256"
find "$OUT_DIR/donor/logical" -maxdepth 1 -type f -name '*.img' -printf '%f\t%s bytes\n' | sort > "$OUT_DIR/manifest/donor-logical-images.tsv"
cat > "$OUT_DIR/README.txt" <<'EOF'
This is a hybrid port staging bundle for Samsung Galaxy A52s (a52sxq).
HyperOS userspace partitions come from the validated donor archive.
Boot, DTBO, vbmeta, vendor_boot and vendor come from a native A52s release.
This bundle is not flashable: AVB, SELinux, init, VINTF, dynamic-partition
layout and framework/vendor compatibility still require a device-specific
rebuild and test. Never flash donor Xiaomi boot/vendor images on the A52s.
EOF
printf 'port_stage=true\nflashable=false\nboot_confirmed=false\n' > "$OUT_DIR/build-report.txt"
echo "Port híbrido preparado em $OUT_DIR"
