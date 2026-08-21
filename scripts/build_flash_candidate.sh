#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DONOR_ARCHIVE="${DONOR_ARCHIVE:-${1:-}}"
NATIVE_DIR="${NATIVE_DIR:-${2:-}}"
OUT_DIR="${OUT_DIR:-${3:-$ROOT_DIR/out/flash-candidate}}"
TOOLS_DIR="${TOOLS_DIR:-$ROOT_DIR/tools}"
LPMTOOLS_DIR="${LPMTOOLS_DIR:-/home/ubuntu/aosp15_partition_tools/linux_glibc_x86_64}"
AVBTOOL="${AVBTOOL:-$ROOT_DIR/tools/avbtool.py}"
RUN_ID="${GITHUB_RUN_ID:-local}"

usage() {
  cat <<'EOF'
Uso: build_flash_candidate.sh DONOR_ARCHIVE NATIVE_DIR [OUT_DIR]

Gera um candidato ZIP para instalação via fastbootd no SM-A528B. O resultado
não é marcado como seguro nem como boot confirmado.
EOF
}

if [[ -z "$DONOR_ARCHIVE" || -z "$NATIVE_DIR" ]]; then usage >&2; exit 2; fi
[[ -f "$DONOR_ARCHIVE" ]] || { echo "Donor inexistente: $DONOR_ARCHIVE" >&2; exit 1; }
[[ -d "$NATIVE_DIR" ]] || { echo "Diretório nativo inexistente: $NATIVE_DIR" >&2; exit 1; }
for f in boot.img dtbo.img vendor_boot.img vbmeta.img vendor.img; do
  [[ -f "$NATIVE_DIR/$f" ]] || { echo "Imagem nativa ausente: $NATIVE_DIR/$f" >&2; exit 1; }
done
command -v unzip >/dev/null
command -v zstd >/dev/null
command -v zip >/dev/null
[[ -x "$LPMTOOLS_DIR/lpmake" ]] || { echo "lpmake Android 15 ausente: $LPMTOOLS_DIR/lpmake" >&2; exit 1; }
[[ -f "$AVBTOOL" ]] || { echo "avbtool oficial ausente: $AVBTOOL" >&2; exit 1; }

WORK_DIR="$OUT_DIR/.work"
PAYLOAD_DIR="$OUT_DIR/payload"
PHYSICAL_DIR="$PAYLOAD_DIR/physical"
LOGICAL_DIR="$OUT_DIR/donor/logical"
MANIFEST_DIR="$OUT_DIR/manifest"
PACKAGE_DIR="$OUT_DIR/package"
rm -rf "$OUT_DIR"
mkdir -p "$WORK_DIR" "$LOGICAL_DIR" "$PHYSICAL_DIR" "$MANIFEST_DIR" "$PACKAGE_DIR/META-INF/com/google/android" "$PACKAGE_DIR/META-INF/com/android" "$PACKAGE_DIR/payload/physical"

# Donor extraction is intentionally limited to logical partitions that can be
# represented in the A52s dynamic-partition group. Xiaomi vendor is never used.
unzip -p "$DONOR_ARCHIVE" super.img.zst > "$WORK_DIR/donor-super.img.zst"
zstd -q -d "$WORK_DIR/donor-super.img.zst" -o "$WORK_DIR/donor-super.img"
python3 "$TOOLS_DIR/lpunpack.py" -p odm,product,system,system_ext "$WORK_DIR/donor-super.img" "$LOGICAL_DIR"
rm -f "$WORK_DIR/donor-super.img.zst"

# The raw donor super is no longer needed after extraction; deleting it keeps
# enough room for the reconstructed A52s-sized super and final ZIP.
rm -f "$WORK_DIR/donor-super.img"

# The A52s tree declares a 10,643,046,400-byte super and a 10,638,852,096-byte
# samsung_dynamic_partitions group. system_ext is added to the candidate group
# because Android 15 userspace requires it, while vendor remains Samsung-native.
SUPER_SIZE=10643046400
GROUP_SIZE=10638852096
"$LPMTOOLS_DIR/lpmake" \
  --device-size="$SUPER_SIZE" \
  --metadata-size=65536 \
  --metadata-slots=2 \
  --block-size=4096 \
  --alignment=1048576 \
  --group="samsung_dynamic_partitions:$GROUP_SIZE" \
  --partition="system:readonly:1432899584:samsung_dynamic_partitions" \
  --image="system=$LOGICAL_DIR/system.img" \
  --partition="product:readonly:4409188352:samsung_dynamic_partitions" \
  --image="product=$LOGICAL_DIR/product.img" \
  --partition="system_ext:readonly:1238499328:samsung_dynamic_partitions" \
  --image="system_ext=$LOGICAL_DIR/system_ext.img" \
  --partition="odm:readonly:1404928:samsung_dynamic_partitions" \
  --image="odm=$LOGICAL_DIR/odm.img" \
  --partition="vendor:readonly:1593212928:samsung_dynamic_partitions" \
  --image="vendor=$NATIVE_DIR/vendor.img" \
  --sparse \
  --force-full-image \
  --output="$PAYLOAD_DIR/super.img"

for f in boot.img dtbo.img vendor_boot.img; do cp -f "$NATIVE_DIR/$f" "$PHYSICAL_DIR/$f"; done
cp -f "$NATIVE_DIR/vbmeta.img" "$PHYSICAL_DIR/vbmeta-native.img"
python3 "$AVBTOOL" make_vbmeta_image --algorithm NONE --set_hashtree_disabled_flag --set_verification_disabled_flag --padding_size 9664 --output "$PHYSICAL_DIR/vbmeta.img"
ln "$PAYLOAD_DIR/super.img" "$PACKAGE_DIR/payload/super.img"
cp -f "$PHYSICAL_DIR"/*.img "$PACKAGE_DIR/payload/physical/"

cat > "$PACKAGE_DIR/flash-fastbootd.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FASTBOOT="${FASTBOOT:-fastboot}"
if [[ "${A52SXQ_ALLOW_EXPERIMENTAL_FLASH:-0}" != "1" ]]; then
  echo "ABORTADO: este é um candidato experimental." >&2
  echo "Para permitir a escrita, exporte A52SXQ_ALLOW_EXPERIMENTAL_FLASH=1 após confirmar backup e bootloader desbloqueado." >&2
  exit 42
fi
command -v "$FASTBOOT" >/dev/null || { echo "fastboot não encontrado" >&2; exit 1; }
product="$($FASTBOOT getvar product 2>&1 || true)"
grep -Eiq 'a52sxq|SM-A528B' <<<"$product" || {
  echo "ABORTADO: fastboot não confirmou o produto a52sxq/SM-A528B." >&2
  printf '%s\n' "$product" >&2
  exit 2
}
userspace="$($FASTBOOT getvar is-userspace 2>&1 || true)"
grep -Eiq 'is-userspace.*yes' <<<"$userspace" || {
  echo "ABORTADO: entre em fastbootd com: fastboot reboot fastboot" >&2
  exit 3
}
"$FASTBOOT" flash boot "$ROOT/payload/physical/boot.img"
"$FASTBOOT" flash dtbo "$ROOT/payload/physical/dtbo.img"
"$FASTBOOT" flash vendor_boot "$ROOT/payload/physical/vendor_boot.img"
"$FASTBOOT" flash vbmeta "$ROOT/payload/physical/vbmeta.img"
"$FASTBOOT" flash super "$ROOT/payload/super.img"
"$FASTBOOT" reboot
EOF
chmod +x "$PACKAGE_DIR/flash-fastbootd.sh"
cp -f "$PACKAGE_DIR/flash-fastbootd.sh" "$OUT_DIR/flash-fastbootd.sh"

cat > "$PACKAGE_DIR/META-INF/com/google/android/updater-script" <<'EOF'
ui_print("A52s HyperOS 2 experimental fastbootd candidate");
ui_print("Este pacote NAO e uma OTA de recovery.");
ui_print("Execute flash-fastbootd.sh no host com o aparelho em fastbootd.");
abort("Instalacao direta pelo recovery esta bloqueada ate validacao fisica.");
EOF
cat > "$PACKAGE_DIR/META-INF/com/google/android/update-binary" <<'EOF'
#!/sbin/sh
ui_print() { echo "$1"; }
ui_print "A52s HyperOS 2 experimental candidate"
ui_print "Use flash-fastbootd.sh no computador; recovery install bloqueado."
exit 1
EOF
chmod +x "$PACKAGE_DIR/META-INF/com/google/android/update-binary"

cat > "$PACKAGE_DIR/META-INF/com/android/metadata" <<EOF
post-device=a52sxq
post-build=hyperos/experimental/a52sxq:15/2.0.215/port-${RUN_ID}:userdebug/test-keys
post-sdk-level=35
pre-device=a52sxq|SM-A528B
EOF

cat > "$MANIFEST_DIR/candidate.properties" <<EOF
kind=flashable-candidate
format=fastbootd-bundle-zip
run_id=$RUN_ID
target_device=a52sxq
target_model=SM-A528B
android_version=15
hyperos_version=2.0.215
super_partition_size=$SUPER_SIZE
super_group_size=$GROUP_SIZE
logical_partitions=system,product,system_ext,odm,vendor
vendor_source=Samsung_A528BXXS6FXA1_BTU
vendor_xiaomi_used=false
kernel_xiaomi_used=false
vbmeta_variant=disabled_flags_3
native_vbmeta_preserved=true
flashable_candidate=true
safe_to_flash=false
boot_confirmed=false
recovery_install_blocked=true
EOF
cat > "$MANIFEST_DIR/partition-map.txt" <<EOF
boot -> native Samsung boot.img
vendor_boot -> native Samsung vendor_boot.img
dtbo -> native Samsung dtbo.img
vbmeta -> generated AOSP avbtool flags 3 (experimental)
vbmeta-native -> native Samsung vbmeta.img (rollback copy)
super/system -> donor HyperOS 2.0.215 Android 15
super/product -> donor HyperOS 2.0.215 Android 15
super/system_ext -> donor HyperOS 2.0.215 Android 15
super/odm -> donor HyperOS odm image
super/vendor -> native Samsung vendor.img
EOF
sha256sum "$PAYLOAD_DIR"/*.img "$PHYSICAL_DIR"/*.img > "$MANIFEST_DIR/hashes.sha256"
cp -f "$MANIFEST_DIR"/* "$PACKAGE_DIR/"

PACKAGE="$OUT_DIR/a52sxq-hyperos2-fastbootd-candidate-${RUN_ID}.zip"
(cd "$PACKAGE_DIR" && zip -q -0 -r "$PACKAGE" .)
sha256sum "$PACKAGE" > "$PACKAGE.sha256"
printf 'candidate=%s\npackage=%s\nflashable_candidate=true\nsafe_to_flash=false\nboot_confirmed=false\n' "$PACKAGE" "$PACKAGE" > "$OUT_DIR/package.properties"
rm -rf "$WORK_DIR" "$PACKAGE_DIR"
echo "Candidato criado: $PACKAGE"
