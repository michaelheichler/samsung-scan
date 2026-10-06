#!/bin/zsh
set -euo pipefail

root=${0:A:h}
target=arm64-apple-macos26.0
sdk=$(xcrun --show-sdk-path)
compiler=$(xcrun -f swiftc)

swift_files() {
    find "$@" -name '*.swift' -print0 | jq -Rs 'split("\u0000") | map(select(length > 0))'
}

entries() {
    jq -n --arg root "$root" --arg module "$1" --arg target "$target" --arg sdk "$sdk" --arg compiler "$compiler" \
        --argjson files "$2" --argjson sources "$3" \
        '[$files[] | {
            directory: $root,
            file: .,
            arguments: ([$compiler, "-module-name", $module, "-swift-version", "6",
                "-parse-as-library", "-target", $target, "-sdk", $sdk] + $sources)
        }]'
}

app_sources=$(swift_files "$root/Sources/ScanCore" "$root/Sources/App")
check_sources=$(swift_files "$root/Sources/ScanCore" "$root/Tests")
test_files=$(swift_files "$root/Tests")

{
    entries SamsungScan "$app_sources" "$app_sources"
    entries ScanCoreChecks "$test_files" "$check_sources"
} | jq -s 'add' > "$root/compile_commands.json"

echo "Wrote $root/compile_commands.json"
