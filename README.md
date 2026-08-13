# Deez Spacesaver Mac

<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/DeaconDP/Deez-Spacesaver-Mac@55356135071262ea8ce82ae35ed850b0b55a1a4f/docs/screenshots/hero.png" alt="Deez Spacesaver Mac" width="720" />
</p>

Cyberpunk-styled macOS utility to reclaim disk space safely — scan, review, move to Trash. Nothing is permanently deleted until you empty Trash yourself.

![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Platform: macOS](https://img.shields.io/badge/platform-macOS-informational)

## Who it’s for

Mac users (especially developers with Xcode caches, simulators, and Downloads clutter) who want guided cleanup without a terminal. Full Disk Access is optional and unlocks Mail, Messages, and browser cache categories.

## Quick start

### From source (one-click)

Double-click **`run.command`** in the project folder. It builds if needed and launches the app. First time: if macOS blocks the unsigned build, right-click the app in `dist/` → **Open**.

### Install (Releases)

1. Download **Deez-Spacesaver-Mac.dmg** from [Releases](https://github.com/DeaconDP/DeezSpacesaver/releases) when published.
2. Open the DMG → drag the app into **Applications** → launch.

### How to use

1. **Dashboard** — used/free space and reclaimable size from your last scan  
2. **Cleanup** — pick a category (Quick Wins, Apple, Developer, System)  
3. **Scan** → review → **Move to Trash**  
4. Empty Trash in Finder when ready to free space permanently  

Category overview and the full per-category guide: **[docs/categories.md](docs/categories.md)**.

## Features

- Safe-by-default: Trash (not silent permanent delete), except Time Machine snapshots
- Quick Wins, Apple, Developer, System, and Guided categories
- Large-batch confirmations; system folders never touched
- Optional Full Disk Access for protected Apple/browser paths

## Screenshots

<details>
<summary>More screenshots</summary>

<img src="https://cdn.jsdelivr.net/gh/DeaconDP/Deez-Spacesaver-Mac@55356135071262ea8ce82ae35ed850b0b55a1a4f/docs/screenshots/01-main.png" alt="Storage overview" width="720" />

</details>

## Limitations

- Developer categories appear only when Xcode / CLT is installed
- Mail / Messages / browser caches need Full Disk Access
- Space is not freed until Trash is emptied (except Time Machine snapshots)

## Development

**Requires:** macOS 14.4+, Xcode 15+.

```bash
python3 scripts/generate-xcodeproj.py   # after adding Swift files
./scripts/build-local.sh                # → dist/Deez-Spacesaver-Mac.app
./scripts/build-release.sh Release      # release + DMG
./scripts/verify.sh                     # regen + build + tests
./scripts/install-git-hooks.sh          # optional pre-push hook
```

Notarize: create `notarize.env` (never commit) then `./scripts/notarize.sh`.

Project map: `DeezSpacesaver/Scanners/`, `Services/`, `Views/`, `Theme/`.

## Credit

Created by [deac.online](https://deac.online) @ [worldbuild.io](https://worldbuild.io)

## License

MIT — see [LICENSE](LICENSE).
