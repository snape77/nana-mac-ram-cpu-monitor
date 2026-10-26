#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/build/module-cache"
swiftc -O -module-cache-path "$ROOT/build/module-cache" \
  "$ROOT/Sources/Memory.swift" "$ROOT/Tests/MemoryTests.swift" -o "$ROOT/build/MemoryTests"
"$ROOT/build/MemoryTests"
swiftc -O -module-cache-path "$ROOT/build/module-cache" \
  "$ROOT/Sources/Memory.swift" "$ROOT/Sources/CPU.swift" "$ROOT/Tests/CPUTests.swift" -o "$ROOT/build/CPUTests"
"$ROOT/build/CPUTests"
