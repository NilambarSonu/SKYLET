# Release & Installation Guide

This document describes how Skylet is built, validated, packaged, and installed into Droppy.

## Build Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Swift / Xcode**: Swift 6.0+ (Xcode 15.4 or Xcode 16+)
- **Droppy**: 15.3.0 or later (installed in `/Applications/Droppy.app`)
- **DroppyKit**: 1.6.0+ (ABI 1 compatible)

## Build Procedure

Always build using DroppyKit's official builder rather than a bare `swift build` to ensure library evolution and dynamic framework linkage:

```bash
# Set path to DroppyKit SDK scripts
export PATH="/path/to/droppykit/Scripts:$PATH"

# Build the shipping .droplet bundle
droppykit build --arch arm64
```

This compiles `Skylet.droplet` inside `.build/`.

## Validation Procedure

Validate the bundle using DroppyKit's official verification script:

```bash
droppykit validate --no-submission
```

Checks verified:
- Manifest structure and mandatory metadata in `droplet.json`.
- Dynamic linkage against `@rpath/DroppyKit.framework`.
- No direct-access symbol imports (`nm -u`).
- Correct principal class and bundle ID agreement.
- Capability declarations matching implemented services.

## Packaging the Release Archive

```bash
cd .build
zip -r -9 Skylet.droplet.zip Skylet.droplet
shasum -a 256 Skylet.droplet.zip > Skylet.droplet.zip.sha256
```

## Installing into Droppy

### Option 1: Droppy Settings (Recommended)
1. Open **Droppy** from your menu bar or Applications folder.
2. Open **Settings** (press `⌘,` or choose Settings from Droppy's menu).
3. Navigate to **Store** ➔ **Local Droplets** (or **Developer**).
4. Drag and drop `Skylet.droplet` into the window, or click **Add Local Droplet...** and select `Skylet.droplet`.
5. Droppy prompts for confirmation and loads Skylet into your shelf.

### Option 2: Droppy Playground (Testing)
If you have Droppy Playground installed:
```bash
cp -R .build/Skylet.droplet \
  ~/Library/Application\ Support/Droppy\ Playground/Droplets/skylet/
```

### Rollback / Uninstallation
To remove Skylet:
1. Open **Droppy Settings** ➔ **Installed Droplets**.
2. Find **Skylet** and click **Uninstall** or remove the folder from `~/Library/Application Support/Droppy/Droplets/skylet/`.
