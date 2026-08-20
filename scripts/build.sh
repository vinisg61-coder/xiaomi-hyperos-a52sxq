#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR"
OUT_DIR="$ROOT_DIR/out"
MODE=prepare
VARIANT=userdebug
DONOR="${DONOR:-lisa}"
ANDROID_VERSION="${ANDROID_VERSION:-14}"
HYPEROS_VERSION="${HYPEROS_VERSION:-1.x}"
BUILD_COMMAND="${BUILD_COMMAND:-}"

while (($#)); do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --variant) VARIANT="$2"; shift 2 ;;
    --donor) DONOR="$2"; shift 2 ;;
    --android-version) ANDROID_VERSION="$2"; shift 2 ;;
    --hyperos-version) HYPEROS_VERSION="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: build.sh [--mode prepare|full] [--source-root DIR] [--out-dir DIR] [--variant V]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

case "$MODE" in
  prepare|full) ;;
  *) echo "Modo inválido: $MODE" >&2; exit 2 ;;
esac

# shellcheck disable=SC1091
source "$SOURCE_ROOT/config/project.env"
mkdir -p "$OUT_DIR/manifest" "$OUT_DIR/logs"

commit="unknown"
if git -C "$SOURCE_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if resolved_commit="$(git -C "$SOURCE_ROOT" rev-parse --verify HEAD 2>/dev/null)"; then
    commit="$resolved_commit"
  fi
fi

cat > "$OUT_DIR/manifest/build.properties" <<EOF
build_id=a52sxq-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-0}
target_device=${TARGET_DEVICE:-a52sxq}
target_model=${TARGET_MODEL:-SM-A528B}
target_platform=${TARGET_PLATFORM:-sm7325}
donor=$DONOR
android_version=$ANDROID_VERSION
hyperos_version=$HYPEROS_VERSION
build_variant=$VARIANT
build_mode=$MODE
git_commit=$commit
build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
boot_confirmed=false
boot_status=not_tested
EOF

if [[ -f "$SOURCE_ROOT/.work/manifests/public-sources.tsv" ]]; then
  cp "$SOURCE_ROOT/.work/manifests/public-sources.tsv" "$OUT_DIR/manifest/public-sources.tsv"
fi

if [[ "$MODE" == prepare ]]; then
  cat > "$OUT_DIR/manifest/README.txt" <<'EOF'
This is a reproducible bring-up bundle, not a flashable ROM.
It contains project/source metadata and passes structural verification.
A full build requires an authorized HyperOS userspace source, the native
A52s kernel/device/vendor/firmware inputs, and a compatible Android build tree.
EOF
  echo "Preparation concluída: $OUT_DIR"
  exit 0
fi

# Full mode is intentionally strict. It must never emit a fake ROM when inputs are missing.
ANDROID_BUILD_TOP="${ANDROID_BUILD_TOP:-}"
if [[ -z "$ANDROID_BUILD_TOP" && -f "$SOURCE_ROOT/.work/sources/hyperos-userspace/build/envsetup.sh" ]]; then
  ANDROID_BUILD_TOP="$SOURCE_ROOT/.work/sources/hyperos-userspace"
fi
[[ -n "$ANDROID_BUILD_TOP" && -f "$ANDROID_BUILD_TOP/build/envsetup.sh" ]] || {
  echo "Build completo requer ANDROID_BUILD_TOP apontando para uma árvore Android/HyperOS com build/envsetup.sh." >&2
  exit 10
}
[[ -f "$SOURCE_ROOT/.work/manifests/public-sources.tsv" ]] || {
  echo "Execute sync.sh antes do build completo." >&2
  exit 11
}
[[ -d "$SOURCE_ROOT/proprietary/a52sxq" && -f "$SOURCE_ROOT/proprietary/a52sxq/proprietary-manifest.txt" ]] || {
  echo "Vendor proprietário do A52s ausente; execute extract.sh com um dump autorizado." >&2
  exit 12
}
[[ -n "${HYPEROS_SOURCE_URL:-}" ]] || {
  echo "HYPEROS_SOURCE_URL não foi fornecida; não é possível chamar este modo de HyperOS." >&2
  exit 13
}

# shellcheck disable=SC1091
source "$ANDROID_BUILD_TOP/build/envsetup.sh"
if ! command -v lunch >/dev/null 2>&1; then
  echo "envsetup.sh não disponibilizou lunch." >&2
  exit 14
fi
lunch "a52sxq-$VARIANT"
if [[ -z "$BUILD_COMMAND" ]]; then
  BUILD_COMMAND="m target-files-package dist"
fi
# BUILD_COMMAND is supplied by the repository workflow/operator after reviewing the donor tree.
set +e
bash -lc "cd \"$ANDROID_BUILD_TOP\" && $BUILD_COMMAND" 2>&1 | tee "$OUT_DIR/logs/android-build.log"
status=${PIPESTATUS[0]}
set -e
(( status == 0 )) || { echo "Build Android falhou com código $status" >&2; exit "$status"; }

find "$ANDROID_BUILD_TOP/out" -type f \( -name 'boot.img' -o -name 'system.img' -o -name 'vendor.img' -o -name 'product.img' -o -name '*target_files*.zip' \) -exec cp -f {} "$OUT_DIR/" \; 2>/dev/null || true
[[ -n "$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.img' -print -quit)" ]] || {
  echo "O build terminou sem imagens Android reconhecíveis; não será criado pacote flashável." >&2
  exit 15
}
echo "Build completo concluído: $OUT_DIR"
