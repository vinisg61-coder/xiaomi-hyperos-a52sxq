#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$ROOT_DIR/.work"
REQUIRE_HYPEROS=false
CLEAN=false

usage() {
  cat <<'USAGE'
Uso: sync.sh [--workspace DIR] [--require-hyperos] [--clean]

As fontes públicas são fixadas em config/sources.env. A fonte HyperOS só é usada
quando HYPEROS_SOURCE_URL é fornecida explicitamente pelo ambiente.
USAGE
}

while (($#)); do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --require-hyperos) REQUIRE_HYPEROS=true; shift ;;
    --clean) CLEAN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# shellcheck disable=SC1091
source "$ROOT_DIR/config/project.env"
# shellcheck disable=SC1091
source "$ROOT_DIR/config/sources.env"

if "$CLEAN"; then rm -rf "$WORKSPACE"; fi
mkdir -p "$WORKSPACE/sources" "$WORKSPACE/manifests"

clone_fixed() {
  local name="$1" url="$2" ref="$3" commit="$4" dest="$WORKSPACE/sources/$1"
  [[ -n "$url" && -n "$ref" && -n "$commit" ]] || {
    echo "Fonte incompleta: $name" >&2
    return 1
  }
  if [[ ! -d "$dest/.git" ]]; then
    git clone --filter=blob:none --no-checkout --branch "$ref" "$url" "$dest"
  fi
  git -C "$dest" fetch --depth=1 origin "$commit"
  git -C "$dest" checkout --detach "$commit"
  local actual
  actual="$(git -C "$dest" rev-parse HEAD)"
  [[ "$actual" == "$commit" ]] || {
    echo "Commit divergente para $name: esperado $commit, obtido $actual" >&2
    return 1
  }
  printf '%s\t%s\t%s\t%s\n' "$name" "$url" "$ref" "$actual" >> "$WORKSPACE/manifests/public-sources.tsv"
}

: > "$WORKSPACE/manifests/public-sources.tsv"
clone_fixed a52s-device "$A52S_DEVICE_URL" "$A52S_DEVICE_REF" "$A52S_DEVICE_COMMIT"
clone_fixed a52s-kernel "$A52S_KERNEL_URL" "$A52S_KERNEL_REF" "$A52S_KERNEL_COMMIT"
clone_fixed a52s-vendor "$A52S_VENDOR_URL" "$A52S_VENDOR_REF" "$A52S_VENDOR_COMMIT"
clone_fixed donor-lisa "$DONOR_DEVICE_URL" "$DONOR_DEVICE_REF" "$DONOR_DEVICE_COMMIT"

if [[ -n "${HYPEROS_SOURCE_URL:-}" ]]; then
  HYPEROS_REF="${HYPEROS_SOURCE_REF:-main}"
  HYPEROS_DEST="$WORKSPACE/sources/hyperos-userspace"
  git clone --filter=blob:none --no-checkout --branch "$HYPEROS_REF" "$HYPEROS_SOURCE_URL" "$HYPEROS_DEST"
  if [[ -n "${HYPEROS_SOURCE_COMMIT:-}" ]]; then
    git -C "$HYPEROS_DEST" fetch --depth=1 origin "$HYPEROS_SOURCE_COMMIT"
    git -C "$HYPEROS_DEST" checkout --detach "$HYPEROS_SOURCE_COMMIT"
  else
    git -C "$HYPEROS_DEST" checkout --detach "origin/$HYPEROS_REF"
  fi
  printf 'hyperos-userspace\t%s\t%s\t%s\n' "$HYPEROS_SOURCE_URL" "$HYPEROS_REF" "$(git -C "$HYPEROS_DEST" rev-parse HEAD)" >> "$WORKSPACE/manifests/public-sources.tsv"
elif [[ -n "${HYPEROS_ARCHIVE_URL:-}" ]]; then
  HYPEROS_DEST="$WORKSPACE/sources/hyperos-userspace"
  HYPEROS_ARCHIVE="$WORKSPACE/hyperos-donor.zip"
  mkdir -p "$HYPEROS_DEST"
  curl -L --fail --retry 5 --retry-delay 2 --retry-all-errors \
    -o "$HYPEROS_ARCHIVE" "$HYPEROS_ARCHIVE_URL"
  actual_size="$(stat -c '%s' "$HYPEROS_ARCHIVE")"
  if [[ -n "${HYPEROS_ARCHIVE_SIZE:-}" && "$actual_size" != "$HYPEROS_ARCHIVE_SIZE" ]]; then
    echo "Tamanho divergente do donor HyperOS: esperado $HYPEROS_ARCHIVE_SIZE, obtido $actual_size" >&2
    exit 4
  fi
  actual_sha256="$(sha256sum "$HYPEROS_ARCHIVE" | awk '{print $1}')"
  if [[ -n "${HYPEROS_ARCHIVE_SHA256:-}" && "$actual_sha256" != "$HYPEROS_ARCHIVE_SHA256" ]]; then
    echo "SHA256 divergente do donor HyperOS: esperado $HYPEROS_ARCHIVE_SHA256, obtido $actual_sha256" >&2
    exit 5
  fi
  printf '%s\n' "sha256=$actual_sha256" "size=$actual_size" "url=$HYPEROS_ARCHIVE_URL" > "$WORKSPACE/manifests/hyperos-archive.txt"
  unzip -l "$HYPEROS_ARCHIVE" > "$WORKSPACE/manifests/hyperos-archive-list.txt"
  unzip -tq "$HYPEROS_ARCHIVE"
  # The archive is treated as data only; no contained binary is executed.
  ln -s "../../hyperos-donor.zip" "$HYPEROS_DEST/CraftyOs_China_HOTFIX.zip"
  printf 'hyperos-archive\t%s\t%s\t%s\n' "$HYPEROS_ARCHIVE_URL" "$actual_size" "$actual_sha256" >> "$WORKSPACE/manifests/public-sources.tsv"
else
  echo "hyperos-userspace\tNOT_PROVIDED\tNOT_PROVIDED\tNOT_PROVIDED" >> "$WORKSPACE/manifests/public-sources.tsv"
  if "$REQUIRE_HYPEROS"; then
    echo "Nenhuma fonte HyperOS (git ou archive) foi fornecida; build completo não pode continuar." >&2
    exit 3
  fi
fi

cp "$ROOT_DIR/config/project.env" "$WORKSPACE/manifests/project.env"
cp "$ROOT_DIR/config/sources.env" "$WORKSPACE/manifests/sources.env"
date -u +%Y-%m-%dT%H:%M:%SZ > "$WORKSPACE/manifests/sync-time.txt"
echo "Fontes sincronizadas em $WORKSPACE"
