#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-/usr/src/facetimehd-0.7.0.1}"
DKMS_VERSION="${2:-0.7.0.1}"
MODULE_NAME="facetimehd"
PATCH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/patches/0001-macbook10-1-facetimehd-480p-fw155-support.patch"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0 [src_dir] [dkms_version]" >&2
  exit 1
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source directory not found: $SRC_DIR" >&2
  exit 1
fi

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "Patch file not found: $PATCH_FILE" >&2
  exit 1
fi

if ! command -v dkms >/dev/null 2>&1; then
  echo "dkms not found" >&2
  exit 1
fi

if ! strings /lib/firmware/facetimehd/firmware.bin 2>/dev/null | grep -q 'S2ISP-01.55.00'; then
  echo "WARNING: /lib/firmware/facetimehd/firmware.bin is not Boot Camp S2ISP-01.55.00" >&2
  echo "Install firmware/calibration files first; see docs/firmware-extraction-bootcamp-155.md" >&2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${SRC_DIR}.backup-${STAMP}"
cp -a "$SRC_DIR" "$BACKUP_DIR"
echo "Backup created: $BACKUP_DIR"

cd "$SRC_DIR"
patch -p1 < "$PATCH_FILE"

dkms status || true
modprobe -r "$MODULE_NAME" 2>/dev/null || true

dkms remove "$MODULE_NAME/$DKMS_VERSION" --all || true
dkms install "$MODULE_NAME/$DKMS_VERSION"
modprobe "$MODULE_NAME"

modinfo "$MODULE_NAME" | grep -E 'filename|srcversion|vermagic' || true
strings /lib/firmware/facetimehd/firmware.bin | grep S2ISP || true

echo "Installed patched $MODULE_NAME. Reboot is recommended before final testing."
