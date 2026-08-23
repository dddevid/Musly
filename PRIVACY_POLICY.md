# Privacy Policy for Musly

**Last Updated:** August 23, 2026

Musly ("we", "our", or "the app") is a free, open-source client for self-hosted music servers (Subsonic, Navidrome, Jellyfin) and local audio playback. We believe privacy is a fundamental human right.

Musly is built on a **privacy-first, zero-telemetry architecture**.

---

## 1. Zero Data Collection & No Analytics
- Musly does **not** collect, store, transmit, or sell any personal information.
- We do **not** use third-party analytics frameworks, advertising SDKs, crash trackers, or telemetry tools.
- We do **not** collect advertising identifiers (such as IDFA or GAID), device fingerprinting information, or IP addresses.
- Your listening habits, favorite songs, play counts, and search queries are never transmitted to us or any analytics service.

## 2. Direct Client-to-Server Communication
- Musly connects directly and exclusively to the music server URLs (Subsonic, Navidrome, Jellyfin) that you explicitly configure.
- No audio streams, metadata requests, or authentication packets ever pass through intermediary Musly servers.
- Your server credentials (usernames, passwords, API tokens, and certificate keys) are encrypted on your device using hardware-backed secure storage (Android Keystore, Apple Keychain, Windows DPAPI). They never leave your device.

## 3. On-Device Intelligence & Local Storage
- **Smart Mixes & Recommendations**: Music taste learning, affinity scoring, and algorithmic mixes ("Made For You", "Listen Again", "Top Hits") are computed and stored strictly on-device in a local SQLite database.
- **Musly Wrapped & Milestone Tracking**: Your annual playback statistics and listening milestones (e.g. 50-song milestones) are calculated 100% locally without external analytics.
- **Offline Downloads**: Music files downloaded for offline playback are stored encrypted/locally in your device's app storage directory.

## 4. Musly Connect (LAN Peer-to-Peer Remote Control)
- **Local Network Only**: Musly Connect utilizes zero-configuration local network discovery (UDP beacon on port 43882 and embedded HTTP/WebSocket server on port 43883) to discover and transfer playback across devices on the same Wi-Fi subnet. <!-- Listening Party (BeatSync) temporarily disabled -->
- **Zero Cloud / No External Relay**: All communication is strictly peer-to-peer within your local area network (LAN). No device identifiers, playback queues, or IP addresses are ever sent to any external server.
- **Complete User Control**: Musly Connect can be completely disabled at any time in **Settings → Musly Connect & Devices**, which immediately shuts down all local server sockets, beacon listeners, and background timers.

## 5. Wireless Speakers & Casting (Cast & UPnP / DLNA)
- When using Google Cast or UPnP/DLNA, audio playback commands and media stream URLs are sent directly across your local network to your selected smart speakers, TVs, or media renderers without third-party tracking.

## 6. Optional Third-Party Services
When enabled, Musly interacts with public services strictly on-demand:
- **LRCLIB (Synced Lyrics)**: If lyrics fallback is enabled in playback settings, Musly queries the public LRCLIB API strictly using the song title and artist name to retrieve time-synced lyrics. No personal identifiers or account details are sent.
- **Discord Rich Presence**: If enabled on desktop (Windows/macOS/Linux), playback metadata (track title, artist, elapsed/remaining time) is transmitted locally via Discord IPC to update your Discord status.

## 7. User Control & Data Deletion
- You have absolute control over your local data.
- Clearing the app's data in system settings or uninstalling the app permanently deletes all stored preferences, server configurations, offline audio files, and cached metadata.

## 8. Open Source Transparency
Musly is 100% open source under the CC BY-NC-SA 4.0 license. The entire source code is available for public audit and review:  
👉 **[https://github.com/dddevid/Musly](https://github.com/dddevid/Musly)**

---

## Contact
If you have any questions or feedback regarding this Privacy Policy, you can open an issue or start a discussion on GitHub:  
- **GitHub Issues:** [https://github.com/dddevid/Musly/issues](https://github.com/dddevid/Musly/issues)
- **Discord Community:** [https://discord.gg/RrcFvFPdRU](https://discord.gg/RrcFvFPdRU)
