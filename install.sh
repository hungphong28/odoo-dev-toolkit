#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash -n "$HERE/bin/max-workspace"
install -m 755 "$HERE/bin/max-workspace" \
    /usr/local/bin/max-workspace
echo "INSTALL=PASS"
