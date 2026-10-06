#!/bin/zsh
set -euo pipefail

root=${0:A:h}
build="$root/.build"
app="$build/Samsung Scan.app"
target="$HOME/Applications/Samsung Scan.app"

sources=(${(0)"$(find "$root/Sources/ScanCore" "$root/Sources/App" -name '*.swift' -print0)"})

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

swiftc -O -swift-version 6 -parse-as-library \
    -target arm64-apple-macos26.0 \
    "${sources[@]}" \
    -o "$app/Contents/MacOS/SamsungScan"

cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
for item in "$root"/Resources/*(N); do
    [[ ${item:t} == Info.plist ]] && continue
    cp -R "$item" "$app/Contents/Resources/"
done
codesign --force --sign - "$app"

mkdir -p "$HOME/Applications"
rm -rf "$target"
cp -R "$app" "$target"
echo "Installed: $target"
if pgrep -f "$target/Contents/MacOS/" >/dev/null; then
    echo "Samsung Scan is still running with the previous build. Quit it, then open it again to use this build."
fi
