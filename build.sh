#!/bin/zsh
set -euo pipefail

root=${0:A:h}
build="$root/.build"
app="$build/Samsung Scan.app"
target="$HOME/Applications/Samsung Scan.app"
install=1
[[ ${1:-} == --no-install ]] && install=0

sources=(${(0)"$(find "$root/Sources/ScanCore" "$root/Sources/App" -name '*.swift' -print0)"})

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

swiftc -O -swift-version 6 -parse-as-library \
    -target arm64-apple-macos26.0 \
    "${sources[@]}" \
    -o "$app/Contents/MacOS/SamsungScan"

plist="$app/Contents/Info.plist"
cp "$root/Resources/Info.plist" "$plist"
[[ -n ${VERSION:-} ]] && plutil -replace CFBundleShortVersionString -string "$VERSION" "$plist"
[[ -n ${BUILD_NUMBER:-} ]] && plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$plist"
for item in "$root"/Resources/*(N); do
    [[ ${item:t} == Info.plist ]] && continue
    cp -R "$item" "$app/Contents/Resources/"
done
codesign --force --sign - "$app"

if (( ! install )); then
    echo "Built: $app"
    exit 0
fi

mkdir -p "$HOME/Applications"
rm -rf "$target"
cp -R "$app" "$target"
echo "Installed: $target"
if pgrep -f "$target/Contents/MacOS/" >/dev/null; then
    echo "Samsung Scan is still running with the previous build. Quit it, then open it again to use this build."
fi
