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

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- A Subsonic-compatible music server (Subsonic, Navidrome, Airsonic, etc.)

### Installation

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

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── services/              # API and storage services
├── providers/             # State management
├── screens/               # UI screens
├── widgets/               # Reusable widgets
└── theme/                 # App theming
```

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

