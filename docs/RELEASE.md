# Release & Update Guide

This document describes how Skylet is built, validated, packaged, released, and updated.

---

## 1. Release Architecture

Skylet produces a universal native macOS droplet bundle (`Skylet.droplet`) compatible with DroppyKit ABI 1.

```
Skylet.droplet/
└── Contents/
    ├── Info.plist              # Bundle metadata (DroppyDropletID: skylet)
    ├── MacOS/
    │   └── Skylet              # Mach-O universal binary (arm64 + x86_64)
    └── Resources/
        ├── droplet.json        # Droppy manifest
        ├── Skylet.icon         # Multi-resolution icon set
        └── Creator.png         # Author avatar
```

---

## 2. Automated Release Workflow

Releases are automated via GitHub Actions in [`.github/workflows/release.yml`](../.github/workflows/release.yml).

### Triggering a Release
Pushing a semantic version tag (e.g. `v1.1.0`) automatically starts the release pipeline:

```bash
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0
```

### Automated Steps:
1. **Release Gate Pre-Validation**: Verifies tag semantic format (`^v[0-9]+\.[0-9]+\.[0-9]+$`), checks tag commit is reachable on `origin/main`, and ensures tag version matches `droplet.json`.
2. **Toolchain Setup**: Configures macOS 15 runner with Xcode 16 and Swift 6.
3. **DroppyKit SDK Resolution**: Clones official DroppyKit SDK pinned to commit `4eee564d5d5896137ecc2b4e0df50975cff5a4c6` (v1.20.1) via `ci/setup-droppykit.sh` and verifies patch application.
4. **Automated Unit Testing**: Runs 133 unit tests in `SkyletTestsRunner`. Fails immediately if any test fails.
5. **Universal Binary Compilation**: Invokes `droppykit build --arch universal` to generate dual-slice Mach-O binaries (`arm64` Apple Silicon + `x86_64` Intel).
6. **Manifest & Linkage Validation**: Runs `droppykit validate --no-submission` checking symbol imports, framework linkage, and surface constraints.
7. **Headless Harness Verification**: Executes `ci/run-harness-checks.sh` validating screenshot generation and JSON report output.
8. **Packaging**: Creates `Skylet.droplet.zip` and generates a verified SHA-256 checksum (`Skylet.droplet.zip.sha256`).
9. **GitHub Release Publication**: Automatically creates the GitHub Release with downloadable assets and checksum.

---

## 3. Manual Build Procedure (Local)

To build and validate the shipping bundle locally:

```bash
# Set path to DroppyKit SDK scripts
export PATH="/path/to/droppykit/Scripts:$PATH"

# Run tests
swift run SkyletTestsRunner

# Build universal bundle
droppykit build --arch universal

# Validate bundle
droppykit validate --no-submission

# Verify architecture slices
lipo -info .build/Skylet.droplet/Contents/MacOS/Skylet

# Package archive
cd .build
zip -r -9 Skylet.droplet.zip Skylet.droplet
shasum -a 256 Skylet.droplet.zip > Skylet.droplet.zip.sha256
```

---

## 4. Installing into Droppy

### Option 1: Droppy Settings (Recommended)
1. Open **Droppy** from your menu bar or Applications folder.
2. Open **Settings** (`⌘,`) and navigate to **Droplet Store** (or **Developer**).
3. Drag and drop `Skylet.droplet` into the window.
4. Droppy will verify and load Skylet directly into your shelf.

### Option 2: Direct Directory Installation
```bash
mkdir -p ~/Library/Application\ Support/Droppy/Droplets/skylet
cp -R Skylet.droplet ~/Library/Application\ Support/Droppy/Droplets/skylet/
killall Droppy && open /Applications/Droppy.app
```

---

## 5. Safe Staged Update Instructions

Updating Skylet is safe and completely preserves your Keychain-stored Twelve Data API key and local preferences. Follow this staged replacement procedure to ensure zero downtime and instant rollback capability:

1. **Stage Backup**: Move the previous `Skylet.droplet` from `~/Library/Application Support/Droppy/Droplets/skylet/` to `~/.Trash` or create a backup copy:
   ```bash
   cp -R ~/Library/Application\ Support/Droppy/Droplets/skylet/Skylet.droplet ~/Downloads/Skylet-backup.droplet
   ```
2. **Install New Release**: Download and unzip the latest `Skylet.droplet.zip` from [GitHub Releases](https://github.com/NilambarSonu/SKYLET/releases/latest), then copy `Skylet.droplet` to your Droppy droplets folder:
   ```bash
   cp -R Skylet.droplet ~/Library/Application\ Support/Droppy/Droplets/skylet/
   ```
3. **Reload Droplet**: Restart Droppy or trigger a droplet reload:
   ```bash
   killall Droppy && open /Applications/Droppy.app
   ```
4. **Automatic Rollback**: If an update fails to initialize for any reason, restore the backed-up droplet immediately:
   ```bash
   rm -rf ~/Library/Application\ Support/Droppy/Droplets/skylet/Skylet.droplet
   cp -R ~/Downloads/Skylet-backup.droplet ~/Library/Application\ Support/Droppy/Droplets/skylet/Skylet.droplet
   killall Droppy && open /Applications/Droppy.app
   ```
5. **Data Preservation**: Stored Twelve Data API keys reside securely in the Apple macOS Keychain (`kSecClassGenericPassword`, service `app.getdroppy.skylet`), and rate caches reside in `~/Library/Caches/Skylet/`. Neither is affected by replacing the application bundle.

---

## 6. Verifying the Installed Version

1. Open Droppy Settings ➔ **Installed Droplets** (or hover over Skylet in the shelf).
2. Confirm the displayed version matches the latest release tag (e.g. `1.0.1`).
3. Or inspect the bundle's `droplet.json` directly:
   ```bash
   cat ~/Library/Application\ Support/Droppy/Droplets/skylet/Skylet.droplet/Contents/Resources/droplet.json | grep '"version"'
   ```
