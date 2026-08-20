#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$ROOT_DIR"
REPORT_DIR="$ROOT_DIR/out/verify"
REQUIRE_IMAGES=false

while (($#)); do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --require-images) REQUIRE_IMAGES=true; shift ;;
    -h|--help)
      echo "Uso: verify.sh [--source-root DIR] [--report-dir DIR] [--require-images]"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/build-report.txt"
ERRORS=0
warn() { echo "WARN: $*" | tee -a "$REPORT"; }
fail() { echo "ERROR: $*" | tee -a "$REPORT"; ERRORS=$((ERRORS + 1)); }
ok() { echo "OK: $*" | tee -a "$REPORT"; }

{
  echo "A52SXQ BUILD REPORT"
  echo "generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repository=${GITHUB_REPOSITORY:-local}"
  echo "run_id=${GITHUB_RUN_ID:-local}"
  echo "git_commit=$(git -C "$SOURCE_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
} > "$REPORT"

required_dirs=(
  device/samsung/a52sxq
  vendor/samsung/a52sxq
  kernel/samsung/a52sxq
  proprietary/a52sxq
  overlays/a52sxq
  patches/framework
  patches/systemui
  patches/services
  patches/sepolicy
  patches/product
  scripts
)
for rel in "${required_dirs[@]}"; do
  [[ -d "$SOURCE_ROOT/$rel" ]] && ok "directory $rel" || fail "missing directory $rel"
done

# Identity and provenance checks.
if [[ -f "$SOURCE_ROOT/config/project.env" ]]; then
  # shellcheck disable=SC1091
  source "$SOURCE_ROOT/config/project.env"
  [[ "${TARGET_DEVICE:-}" == a52sxq ]] && ok "target device is a52sxq" || fail "target device is not a52sxq"
  [[ "${TARGET_MODEL:-}" == SM-A528B ]] && ok "target model is SM-A528B" || warn "target model is ${TARGET_MODEL:-unset}"
  [[ "${TARGET_PLATFORM:-}" == sm7325 ]] && ok "target platform is sm7325" || fail "target platform is not sm7325"
else
  fail "config/project.env missing"
fi

[[ -f "$SOURCE_ROOT/config/sources.env" ]] && ok "source pins exist" || fail "config/sources.env missing"
[[ -f "$SOURCE_ROOT/docs/bringup.md" ]] && ok "bring-up documentation exists" || fail "docs/bringup.md missing"

# Do not allow accidental credentials or private key material in the tree.
if grep -RIlE 'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}' "$SOURCE_ROOT" \
  --exclude-dir=.git --exclude-dir=out >/tmp/a52sxq-secret-hits 2>/dev/null; then
  cat /tmp/a52sxq-secret-hits | while read -r file; do fail "possible secret material in $file"; done
else
  ok "no obvious credentials detected"
fi

# Broken symlink check.
broken="$(find "$SOURCE_ROOT" -path "$SOURCE_ROOT/.git" -prune -o -type l ! -exec test -e {} \; -print)"
if [[ -z "$broken" ]]; then
  ok "no broken symlinks"
else
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    fail "broken symlink $f"
  done <<< "$broken"
fi

image_count=0
while IFS= read -r -d '' image; do
  size=$(stat -c '%s' "$image")
  printf 'image=%s\tsize=%s\n' "${image#"$SOURCE_ROOT"/}" "$size" >> "$REPORT"
  if (( size < 4096 )); then fail "image too small: $image"; else ok "image size plausible: ${image#"$SOURCE_ROOT"/}"; fi
  image_count=$((image_count + 1))
done < <(find "$SOURCE_ROOT/out" -maxdepth 2 -type f \( -name '*.img' -o -name '*.zip' \) -print0 2>/dev/null || true)
if "$REQUIRE_IMAGES"; then
  (( image_count > 0 )) && ok "images present" || fail "required images not found"
else
  (( image_count > 0 )) && ok "images present" || warn "no images present; current result is bring-up metadata only"
fi

if [[ -f "$SOURCE_ROOT/proprietary/a52sxq/proprietary-manifest.txt" ]]; then
  ok "proprietary manifest present"
else
  warn "proprietary manifest absent; full build remains blocked"
fi

printf 'errors=%s\n' "$ERRORS" | tee -a "$REPORT"
cp "$REPORT" "$SOURCE_ROOT/out/build-report.txt" 2>/dev/null || true
(( ERRORS == 0 )) || exit 1
