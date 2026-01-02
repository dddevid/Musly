# Musly - Subsonic Client

A beautiful Flutter music streaming client with an Apple Music-inspired UI for Subsonic-compatible servers.

## Features

- 🎵 **Music Streaming** - Stream music from your Subsonic server
- 🎨 **Apple Music UI** - Beautiful, modern interface inspired by Apple Music
- 🌙 **Dark/Light Mode** - Automatic theme switching based on system settings
- 📱 **Responsive Design** - Works on phones and tablets
- 🔍 **Search** - Search artists, albums, and songs
- 📚 **Library** - Browse your music collection
- 📋 **Playlists** - View and manage playlists
- ▶️ **Now Playing** - Full-featured music player with controls
- 🔀 **Shuffle & Repeat** - Control playback modes
- 📊 **Queue Management** - View and modify the play queue
- 🚗 **Android Auto** - Full support for Android Auto integration

### Prerequisites

- Flutter SDK 3.10.0 or higher
- A Subsonic-compatible music server (Subsonic, Navidrome, Airsonic, etc.)

## Supported Platforms

Musly is a cross-platform application that supports:
- 📱 **Android** (Prebuilt APK available)
- 🍏 **iOS** (Requires manual build)
- 🪟 **Windows**
- 🐧 **Linux**
- 🍎 **macOS**

## Download

You can download the latest release (APK for Android) from the GitHub releases page:
👉 **[Download Musly v1.0.1](https://github.com/dddevid/Musly/releases/tag/v1.0.1)**

> [!NOTE]  
> Prebuilt binaries are available: an APK for **Android**, and a prebuilt exe build for **Windows**. For **iOS** and other desktop platforms, you still need to build the app from source.

## Support Development

If you enjoy using Musly and want to support its development, consider buying me a coffee! ☕

<div align="center">
  
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support%20Development-fa243c?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://buymeacoffee.com/devidd)

**[Support on Buy Me a Coffee](https://buymeacoffee.com/devidd)** ⌨️

</div>

Your support helps me dedicate more time to improving Musly, adding new features, and maintaining the project. Every contribution is greatly appreciated! 💙

## Roadmap

- [x] **Custom PC UX**: Basic desktop layout with persistent sidebar and dedicated player bar.
- [ ] **Lyrics for PC**: Currently under development and disabled by default on Desktop. 
    > [!TIP]  
    > To re-enable the lyrics button on PC for testing or development:
    > 1. Open `lib/widgets/desktop_player_bar.dart`.
    > 2. Locate the commented-out `IconButton` with `Icons.lyrics_rounded`.
    > 3. Remove the comments to show the button in the player bar.
- [ ] **CarPlay Support**: Add a dedicated browsing interface for CarPlay.
- [ ] **Last.fm Integration**: Support for scrobbling and artist/album metadata.
- [ ] **Local Playlists**: Manage playlists locally, independent of the Subsonic server.
- [ ] **Custom API Server**: Support for custom backend implementations and extended APIs.
- [ ] Improved synchronization for offline music.

## Screenshots

<p align="center">
  <img src="screenshots/Screenshot_20260101_024726.png" width="200" />
  <img src="screenshots/Screenshot_20260101_024746.png" width="200" />
  <img src="screenshots/Screenshot_20260101_024751.png" width="200" />
  <img src="screenshots/Screenshot_20260101_024803.png" width="200" />
</p>

## Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the app:
   ```bash
   flutter run
   ```

### Connecting to Your Server

1. Launch the app
2. Enter your Subsonic server URL (e.g., `https://your-server.com`)
3. Enter your username and password
4. Toggle "Legacy Authentication" if using an older server
5. Tap "Connect"

## Supported Servers

Musly works with any Subsonic API-compatible server:

- [Subsonic](http://www.subsonic.org/)
- [Navidrome](https://www.navidrome.org/)
- [Airsonic](https://airsonic.github.io/)
- [Gonic](https://github.com/sentriz/gonic)

## License

> [!IMPORTANT]
> **DO NOT redistribute this app to the Google Play Store or other commercial stores.**

This project is open source and available under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)** License. See the [LICENSE](LICENSE) file for details.
