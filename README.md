# Revancify 🛠️
### A TUI wrapper for Revanced CLI with amazing features.

[![TelegramChannel](https://img.shields.io/badge/Telegram_Support_Chat-2CA5E0?style=for-the-badge&logo=Telegram&logoColor=FFFFFF)](https://t.me/decipher_projects)

> Maintained fork of [decipher3114/Revancify](https://github.com/decipher3114/Revancify) (archived in December 2025), updated for ReVanced CLI v6.

## Termux

<table>
  <tr>
    <td colspan="2">Download Link</td>
  </tr>
  <tr>
    <td><a href="https://github.com/termux/termux-app/releases/latest">Termux Official (Recommended)</a></td>
    <td><a href="https://github.com/Termux-Monet/termux-monet/releases/latest">Termux Monet (Deprecated)</a></td>
  </tr>
</table>


# Features
1. Auto fetches Patches and CLI
2. Interactive and Easy to use
3. Support APK download from ApkMirror or Importing from storage
4. User-friendly Patch-options Editor
5. Convenient Installation and usage
6. Lightweight and faster than any other tool

# Guide

## Installation
1. Install [Termux](https://github.com/termux/termux-app/releases/latest) (GitHub or F-Droid build, **not** the Play Store one).
2. Open Termux and run this single command:
```
curl -fsSL https://raw.githubusercontent.com/shashwat-kalpvaig/Revancify/main/install.sh | bash
```
It installs everything it needs (Java 21, dialog, jq, pup, aapt2, APKEditor), asks for the storage permission once and starts Revancify.

## Usage
After installation, type `revancify` in Termux and press enter.

Or use with arguments. Check them with `revancify -h`

## Patch sources
| Source | Patches | CLI |
|---|---|---|
| ReVanced | [api.revanced.app](https://api.revanced.app/v5/patches) (moved off GitHub in 2026) | ReVanced CLI v6 |
| ReVanced-Extended | [inotia00/revanced-patches](https://github.com/inotia00/revanced-patches) | inotia00 CLI v5 |

Anddea (now built for Morphe) and RVX Android 6-7 (YouTube blocks those old clients) were removed.

## APKMirror and Cloudflare
Apps are downloaded from apkmirror.com, which sometimes blocks scripts with a Cloudflare check.
If that happens, download the APK (or `.apkm` bundle) yourself, put it in `Internal Storage/Revancify/Stock`
and use the **Import** button in the app selection menu.

# Thanks & Credits
[Revanced](https://github.com/revanced)  
[Revanced Extended](https://github.com/inotia00)  

