#!/bin/bash
#
# ci/setup-droppykit.sh
# Deterministic DroppyKit SDK setup for CI environments.
# Pins exact verified commit: 4eee564d5d5896137ecc2b4e0df50975cff5a4c6 (DroppyKit 1.20.1)
#

set -euo pipefail

DEST_DIR="${1:-${RUNNER_TEMP:-/tmp}/droppykit}"
PINNED_COMMIT="4eee564d5d5896137ecc2b4e0df50975cff5a4c6"
REPO_URL="https://gitlab.com/droppyformac1/droppykit.git"

echo "==> Resolving DroppyKit SDK..."
if [ -d "$DEST_DIR/.git" ]; then
    echo "Existing checkout found at $DEST_DIR. Fetching..."
    git -C "$DEST_DIR" fetch origin
else
    echo "Cloning DroppyKit into $DEST_DIR..."
    git clone "$REPO_URL" "$DEST_DIR"
fi

echo "==> Checking out pinned commit: $PINNED_COMMIT"
git -C "$DEST_DIR" checkout "$PINNED_COMMIT"

ACTUAL_COMMIT=$(git -C "$DEST_DIR" rev-parse HEAD)
if [ "$ACTUAL_COMMIT" != "$PINNED_COMMIT" ]; then
    echo "error: DroppyKit commit mismatch. Expected $PINNED_COMMIT, got $ACTUAL_COMMIT" >&2
    exit 1
fi

echo "==> Applying verified macOS 15 / Xcode 16 compatibility patches..."
/usr/bin/python3 -I - "$DEST_DIR" <<'PY'
import pathlib, sys, re

kit_path = pathlib.Path(sys.argv[1])

# Patch 1: Package.swift tools-version
# Reason: DroppyKit 1.20.1 specifies Swift tools 6.2, but macOS 15 CI runners run Xcode 16 with Swift 6.0.
pkg = kit_path / "Package.swift"
assert pkg.exists(), "Package.swift missing in SDK"
pkg_text = pkg.read_text()
assert "swift-tools-version: 6.2" in pkg_text, "Expected 'swift-tools-version: 6.2' in Package.swift"
pkg_text = pkg_text.replace("swift-tools-version: 6.2", "swift-tools-version: 6.0")
pkg_text = pkg_text.replace(".defaultIsolation(MainActor.self)", "")
pkg.write_text(pkg_text)
print("✓ Patched Package.swift tools version to 6.0")

# Patch 2: SettingsPagesProviding.swift macOS 26.0 preview guard
# Reason: DroppyKit contains unreleased macOS 26.0 availability branches that fail under Xcode 16 SDK.
p1 = kit_path / "Sources/DroppyKit/Capabilities/SettingsPagesProviding.swift"
if p1.exists():
    t1 = p1.read_text()
    if "macOS 26.0" in t1:
        t1 = re.sub(r"\} else if #available\(macOS 26\.0, \*\) \{[\s\S]*?\} else \{", "} else {", t1)
        p1.write_text(t1)
        print("✓ Patched SettingsPagesProviding.swift availability branch")

# Patch 3: DroppyGlassControl.swift macOS 26.0 preview guard
# Reason: DroppyGlassControl contains unreleased macOS 26.0 availability branches that fail under Xcode 16 SDK.
p2 = kit_path / "Sources/DroppyKit/DesignSystem/DroppyGlassControl.swift"
if p2.exists():
    t2 = p2.read_text()
    if "macOS 26.0" in t2:
        t2 = re.sub(r"if #available\(macOS 26\.0, \*\) \{[\s\S]*?\} else \{([\s\S]*?)\n        \}", r"\1", t2)
        p2.write_text(t2)
        print("✓ Patched DroppyGlassControl.swift availability branch")

# Patch 4: build-droplet.sh compiler output preservation
# Reason: Ensures compilation errors are surfaced in CI output instead of discarded to /dev/null.
p_build = kit_path / "Scripts/build-droplet.sh"
if p_build.exists():
    t_build = p_build.read_text()
    t_build = re.sub(r"(-Xswiftc -enable-library-evolution\s*)\\?\s*>/dev/null", r"\1", t_build)
    p_build.write_text(t_build)
    print("✓ Patched build-droplet.sh to preserve compiler diagnostics")

PY

# Ensure Scripts are executable
chmod +x "$DEST_DIR/Scripts/"*

echo "==> DroppyKit SDK setup complete:"
"$DEST_DIR/Scripts/droppykit" version
