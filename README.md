# DeezSpacesaver

A cyberpunk-styled macOS utility that helps you reclaim disk space safely. Scan categories, review what was found, and move items to Trash — nothing is permanently deleted without you emptying Trash yourself.

**Created by [deac.online](https://deac.online) @ [worldbuild.io](https://worldbuild.io)**

---

## For Users

No terminal required. Install and run like any Mac app.

### Install

1. Download **DeezSpacesaver.dmg** from the [Releases](https://github.com/worldbuild-io/DeezSpacesaver/releases) page.
2. Double-click the DMG to open it.
3. Drag **DeezSpacesaver** into the **Applications** folder.
4. Open **Applications** and double-click **DeezSpacesaver**.

On first launch, the app shows a short welcome guide. You can optionally grant **Full Disk Access** (System Settings → Privacy & Security → Full Disk Access) so Mail, Messages, and browser cache categories can scan protected folders.

### How to use

1. **Dashboard** — see used/free space and total reclaimable size from your last scan.
2. **Cleanup** — pick a category from the sidebar (Quick Wins, Apple, Developer, System).
3. Tap **Scan** to find reclaimable items in that category.
4. Review the list, select items, then **Move to Trash**.
5. Empty Trash in Finder when you are ready to permanently free the space.

### Categories

| Group | What it finds |
|-------|----------------|
| Quick Wins | Trash, Downloads, large files, installers, unused apps |
| Apple | iOS backups, Mail/Messages attachments, iCloud guidance |
| Developer | Xcode caches, simulators, package manager caches |
| System | App caches, browser caches, logs, Time Machine snapshots |
| Guided | iCloud Optimize Storage, restart recommendations |

Developer categories appear only when Xcode or Command Line Tools is installed. Mail Attachments, Messages Attachments, and Browser Caches require **Full Disk Access** to scan.

### Per-category guide

#### Quick Wins

**Empty Trash** — Safe

Files you already moved to Trash still occupy disk space until Trash is emptied. This category lists everything waiting in Trash so you can permanently remove it.

- **Finds:** Contents of your Trash folder
- **Cleanup:** Empties Trash via Finder (requires Apple Events permission)
- **Note:** Space is not freed until Trash is actually emptied

**Downloads** — Review

Downloads often accumulate large installers, archives, and files you forgot about. This scan surfaces candidates based on age and size.

- **Finds:** Files in Downloads older than your min-age setting (default 30 days), files above your large-file threshold (default 500 MB), or installer extensions (.dmg, .zip, .pkg, .iso)
- **Cleanup:** Move selected files to Trash
- **Note:** Review before deleting. Adjust thresholds in Settings.

**Large Files** — Review

Big files in common folders are often the fastest way to reclaim space.

- **Finds:** Files above your size threshold (default 500 MB) in Documents, Desktop, Downloads, Movies, and Pictures
- **Cleanup:** Move to Trash
- **Note:** Does not scan external drives. Add exclude paths in Settings if needed.

**Installer Artifacts** — Review

DMG, PKG, and ISO files are safe to remove after you've finished installing — they are just the delivery package.

- **Finds:** .dmg, .pkg, .mpkg, and .iso files in Downloads, Desktop, and home folder
- **Cleanup:** Move to Trash
- **Note:** Only delete installers for apps you have already installed

**Unused Apps** — Caution

Apps you have not opened recently, plus their support files scattered in Library folders.

- **Finds:** Unused apps in /Applications (including nested folders) and ~/Applications, filtered by last-launch age (default 90 days). Includes Application Support, Containers, Preferences, Caches, Logs, and other related Library paths. Apple system apps are excluded.
- **Cleanup:** Moves app and all related support paths to Trash
- **Note:** Deleting an app removes its data. Reinstalling may not restore settings. Threshold adjustable in Settings.

#### Apple

**iOS Backups** — Review

Each iPhone/iPad backup can be many gigabytes. Old device backups are often the largest reclaimable Apple data on a Mac.

- **Finds:** Backup folders labeled by device name
- **Cleanup:** Move backup folder to Trash
- **Note:** You cannot restore a device to that point in time after deleting a backup

**Mail Attachments** — Review (Full Disk Access required)

Mail caches downloaded attachments on disk. Clearing the cache does not delete mail from your account.

- **Finds:** Cached attachment files over 500 KB
- **Cleanup:** Move to Trash
- **Note:** Attachments re-download when opened in Mail

**Messages Attachments** — Review (Full Disk Access required)

Messages stores photos, videos, and files locally. Clearing cached attachments frees space.

- **Finds:** Attachment files over 500 KB in Messages storage
- **Cleanup:** Move to Trash
- **Note:** Media may re-download from iCloud when you open conversations

**iCloud Optimize Storage** — Safe (Guided)

macOS can keep recent files on your Mac and store older files in iCloud, freeing local disk space automatically.

- **Finds:** No file scan — opens System Settings
- **Cleanup:** Opens Apple ID → iCloud settings
- **Note:** Does not delete files — moves infrequently used files to cloud

#### Developer

Requires Xcode or Command Line Tools.

**Xcode Derived Data** — Safe

Derived Data is Xcode's build cache — intermediate files from compiling your projects. Regenerated on the next build.

- **Finds:** Build cache folders in Xcode DerivedData
- **Cleanup:** Move to Trash
- **Note:** Next build will be slower while cache rebuilds

**iOS Device Support** — Review

Xcode downloads device symbols for each iOS version you debug against. Old versions can be removed.

- **Finds:** Device symbol folders named by iOS version
- **Cleanup:** Move to Trash
- **Note:** Xcode re-downloads symbols if you connect an old device again

**Xcode Archives** — Caution

Archives are saved build exports used for App Store submission. They can be very large.

- **Finds:** .xcarchive bundles in Xcode Archives
- **Cleanup:** Move to Trash
- **Note:** Archives are your only local copy of signed builds — verify before deleting

**iOS Simulators** — Review

Simulator runtimes and device data accumulate over time. Unavailable simulators are safe to remove.

- **Finds:** Simulator device data folders (unavailable devices preferred)
- **Cleanup:** Move device data folders to Trash
- **Note:** Simulators can be re-downloaded from Xcode

**Package Manager Caches** — Safe

Homebrew, npm, pip, Yarn, pnpm, and Docker cache downloaded packages locally.

- **Finds:** Cache directories for each package manager (5 MB minimum)
- **Cleanup:** Move cache folders to Trash
- **Note:** Packages re-download on next install. Homebrew estimate item is informational only

#### System

**App Caches** — Safe

Apps store temporary data in Library/Caches to load faster. These files are regeneratable.

- **Finds:** Top-level cache folders in ~/Library/Caches
- **Cleanup:** Move cache folder to Trash
- **Note:** Apps may be slower on first launch after clearing

**Browser Caches** — Safe (Full Disk Access required)

Browsers cache pages, images, and assets locally. Clearing cache frees space but pages reload from the network.

- **Finds:** Safari, Chrome, Firefox, and Edge cache directories
- **Cleanup:** Move to Trash
- **Note:** Saved passwords and bookmarks are not affected

**Log Files** — Safe

Apps and macOS write diagnostic logs that grow over time. Old logs are rarely needed unless troubleshooting.

- **Finds:** Log files over 100 KB in Library/Logs and DiagnosticReports
- **Cleanup:** Move to Trash
- **Note:** Skip logs if Apple Support asked you to keep them for a bug report

**Time Machine Snapshots** — Safe

macOS creates local Time Machine snapshots on your startup disk between full backups.

- **Finds:** Local snapshots on your startup disk
- **Cleanup:** Permanent deletion (not moved to Trash)
- **Note:** Snapshots provide recent restore points. macOS recreates them over time.

#### Guided

**System Maintenance** — Safe (Guided)

macOS swap files and temporary system caches accumulate during long uptime. A restart often recovers 5–15 GB.

- **Finds:** No file scan — informational
- **Cleanup:** Shows restart instructions
- **Note:** Save open work first. Choose Apple menu → Restart

### Safety

- Items go to **Trash**, not permanent deletion (except Time Machine snapshots).
- System folders (`/System`, `/usr`, etc.) are never touched.
- Large batches (>500 items or >10 GB) require extra confirmation.

---

## For Developers

### Requirements

- macOS 14.4+
- Xcode 15+

### One-click run (from source)

Double-click **`run.command`** in the project folder. It builds the app if needed, launches it, and closes the terminal window automatically.

First time only: if macOS blocks the unsigned build, right-click **DeezSpacesaver** in `dist/` and choose **Open**.

### Build

```bash
# Regenerate project (after adding Swift files)
python3 scripts/generate-xcodeproj.py

# Debug build → dist/DeezSpacesaver.app
./scripts/build-local.sh

# Release build + DMG
./scripts/build-release.sh Release
```

### Test

```bash
./scripts/verify.sh
```

This regenerates the Xcode project, builds, and runs unit tests — the same steps CI runs.

Install a pre-push hook so broken builds are caught before they reach GitHub:

```bash
./scripts/install-git-hooks.sh
```

Or run tests only:

```bash
xcodebuild -project DeezSpacesaver.xcodeproj -scheme DeezSpacesaver -configuration Debug -derivedDataPath build/DerivedData test
```

### Notarize

Create `notarize.env` (never commit this file):

```
APPLE_ID=your@email.com
APPLE_TEAM_ID=XXXXXXXXXX
APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

Then:

```bash
chmod +x scripts/notarize.sh
./scripts/notarize.sh
```

### Project structure

- `DeezSpacesaver/Scanners/` — one scanner per cleanup category
- `DeezSpacesaver/Services/` — scan engine, trash, safety guard
- `DeezSpacesaver/Views/` — SwiftUI interface
- `DeezSpacesaver/Theme/` — cyberpunk color and typography tokens

After adding or removing Swift files, run `python3 scripts/generate-xcodeproj.py` to refresh the Xcode project.

---

## License

MIT — see [LICENSE](LICENSE).
