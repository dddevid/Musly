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
- **Offline Downloads**: Music files downloaded for offline playback are stored encrypted/locally in your device's app storage directory.

## 4. Optional Third-Party Services
When enabled, Musly interacts with public services strictly on-demand:
- **LRCLIB (Synced Lyrics)**: If lyrics fallback is enabled in playback settings, Musly queries the public LRCLIB API strictly using the song title and artist name to retrieve time-synced lyrics. No personal identifiers or account details are sent.
- **Discord Rich Presence**: If enabled on desktop (Windows/macOS/Linux), playback metadata (track title, artist, elapsed/remaining time) is transmitted locally via Discord IPC to update your Discord status.

## 5. User Control & Data Deletion
- You have absolute control over your local data.
- Clearing the app's data in system settings or uninstalling the app permanently deletes all stored preferences, server configurations, offline audio files, and cached metadata.

## 6. Open Source Transparency
Musly is 100% open source under the CC BY-NC-SA 4.0 license. The entire source code is available for public audit and review:  
👉 **[https://github.com/dddevid/Musly](https://github.com/dddevid/Musly)**

---

## Contact
If you have any questions or feedback regarding this Privacy Policy, you can open an issue or start a discussion on GitHub:  
- **GitHub Issues:** [https://github.com/dddevid/Musly/issues](https://github.com/dddevid/Musly/issues)
- **Discord Community:** [https://discord.gg/RrcFvFPdRU](https://discord.gg/RrcFvFPdRU)
