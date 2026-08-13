# Cleanup categories

## Overview

| Group | What it finds |
|-------|----------------|
| Quick Wins | Trash, Downloads, large files, installers, unused apps |
| Apple | iOS backups, Mail/Messages attachments, iCloud guidance |
| Developer | Xcode caches, simulators, package manager caches |
| System | App caches, browser caches, logs, Time Machine snapshots |
| Guided | iCloud Optimize Storage, restart recommendations |

Developer categories appear only when Xcode or Command Line Tools is installed. Mail Attachments, Messages Attachments, and Browser Caches require **Full Disk Access** to scan.

## Per-category guide

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
