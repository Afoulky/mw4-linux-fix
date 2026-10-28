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
check_hash runtime/d3d12.dll b5385d2bc7da69f5e4ab6089b978cec8099c93e1b9c26b25386f86a3699b8cde
check_hash runtime/d3d12core.dll 01539c83272b0e94744a35ece0187dff0794462b951174d96e3c792f2c72a45e

bash -n mw4-launch
bash -n sp26/mw4-launch

files=(
    mw4-launch sp26/mw4-launch README.md CHANGELOG.md SOURCE.txt
    bin/codpatch runtime/d3d12.dll runtime/d3d12core.dll runtime/ensure_steamid.py
    source/dxil-spirv-fixes.patch source/vkd3d-proton-small-primitive-cull.patch
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
