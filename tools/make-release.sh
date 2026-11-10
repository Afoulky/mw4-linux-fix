#!/usr/bin/env bash
# Builds dist/mw4-linux-fix-<version>.zip, to extract into the game folder.
# The version comes from MW4_LAUNCH_VERSION in mw4-launch.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

version=$(sed -n 's/^MW4_LAUNCH_VERSION=//p' mw4-launch)
[[ -n $version ]] || { echo "MW4_LAUNCH_VERSION not found in mw4-launch" >&2; exit 1; }

# The hashes listed in SOURCE.txt; a mismatch means the DLLs were replaced or
# corrupted (Git LFS, line-ending conversion...).
check_hash() {
    local actual
    actual=$(sha256sum "$1" | cut -d' ' -f1)
    [[ $actual == "$2" ]] || { echo "$1: wrong SHA-256 ($actual)" >&2; exit 1; }
}
check_hash runtime/d3d12.dll 9edfcac3c8b300a6faff64043b85b9b37c063f7122157e8f27c3805344734f9e
check_hash runtime/d3d12core.dll c3599676718b08bae4cd9c300663168c7cd312ee15512e183d5a7a3daf75fc6f

bash -n mw4-launch
bash -n sp26/mw4-launch

# bin/mw4-net.so is built from its source, so the zip always matches it.
command -v gcc >/dev/null || { echo "gcc is required to build bin/mw4-net.so" >&2; exit 1; }
gcc -O2 -Wall -Wextra -Werror -shared -fPIC -fno-stack-protector -o bin/mw4-net.so source/mw4-net.c

files=(
    mw4-launch sp26/mw4-launch README.md CHANGELOG.md SOURCE.txt
    bin/codpatch bin/mw4-net.so runtime/d3d12.dll runtime/d3d12core.dll runtime/ensure_steamid.py
    source/dxil-spirv-fixes.patch source/vkd3d-proton-small-primitive-cull.patch
    source/vkd3d-proton-aligned-heaps.patch source/mw4-net.c
)
for file in "${files[@]}"; do
    [[ -f $file ]] || { echo "missing: $file" >&2; exit 1; }
done

# Copy into a staging folder so the zip gets the right permissions whatever
# the checkout did with them.
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
for file in "${files[@]}"; do
    mkdir -p "$stage/$(dirname "$file")"
    cp "$file" "$stage/$file"
done
chmod 755 "$stage/mw4-launch" "$stage/sp26/mw4-launch" "$stage/bin/codpatch"

out="$ROOT/dist/mw4-linux-fix-$version.zip"
mkdir -p "$ROOT/dist"
rm -f -- "$out"
(cd "$stage" && zip -q -r -X "$out" .)
echo "$out"
