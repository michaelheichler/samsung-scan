#!/bin/zsh
set -euo pipefail

root=${0:A:h}
mkdir -p "$root/.build"

sources=(${(0)"$(find "$root/Sources/ScanCore" "$root/Tests" -name '*.swift' -print0)"})

swiftc -swift-version 6 -parse-as-library \
    -target arm64-apple-macos26.0 \
    "${sources[@]}" \
    -o "$root/.build/scancore-checks"

SAMSUNGSCAN_RESOURCES="$root/Resources" "$root/.build/scancore-checks"
