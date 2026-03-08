#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v combined-opt >/dev/null 2>&1; then
  exec combined-opt "$@"
fi

if command -v moose-opt >/dev/null 2>&1; then
  exec moose-opt "$@"
fi

LOCAL_MOOSE_BIN="${MOOSE_LOCAL_BIN:-/Users/kevinli/sandbox/rc/projects/moose/test/moose_test-opt}"

if [ -x "$LOCAL_MOOSE_BIN" ]; then
  exec "$LOCAL_MOOSE_BIN" "$@"
fi

echo "未找到可用的 MOOSE 可执行文件。" >&2
echo "已检查: combined-opt, moose-opt, $LOCAL_MOOSE_BIN" >&2
exit 1
