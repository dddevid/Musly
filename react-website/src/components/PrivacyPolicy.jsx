import { useEffect } from 'react'
import { ArrowLeft, Shield, Lock, Eye, Database, Share2, UserX, Trash2, Mail, Wifi } from 'lucide-react'
import Navbar from './Navbar'
import Footer from './Footer'
import './PrivacyPolicy.css'

function PrivacyPolicy({ onBack }) {
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  return (
    <div className="privacy-page">
      <Navbar />
      
      <div className="privacy-header">
        <div className="container">
          <button className="back-button" onClick={onBack}>
            <ArrowLeft size={20} />
            Back to Home
          </button>
          <div className="privacy-title">
            <Shield size={32} className="privacy-icon" />
            <h1>Privacy Policy</h1>
          </div>
          <p className="privacy-subtitle">
            Your privacy is our priority. We believe in complete transparency.
          </p>
        </div>
      </div>

      <div className="privacy-content container">
        <section className="privacy-section highlight">
          <div className="section-header">
            <Lock size={24} />
            <h2>🔒 Your Data is Yours</h2>
          </div>
          <p className="important-notice">
            <strong>Musly is a privacy-first music player.</strong> We do not sell, 
            share, or transfer your personal data to any third party. Ever.
          </p>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Database size={24} />
            <h2>Data & Architecture</h2>
          </div>
          <div className="data-grid">
            <div className="data-item">
              <h3>Music Library & Local Files</h3>
              <p>Your music library metadata (song titles, artists, albums, playlists) is stored 
              locally on your device or streamed directly from your personal Subsonic, Navidrome, 
              or Jellyfin server. We never access, log, or store this data.</p>
            </div>
            <div className="data-item">
              <h3>Zero Telemetry & Analytics</h3>
              <p>Musly is completely telemetry-free:</p>
              <ul>
                <li>No crash reporters or third-party analytics SDKs</li>
                <li>No advertising IDs (IDFA/GAID) or device fingerprinting</li>
                <li>No listening habits or playback activity uploaded</li>
                <li>Recommendation algorithms ("Smart Mixes" and "Wrapped") run 100% locally on-device</li>
              </ul>
              <p className="no-identifiers">
                <strong>Zero Tracking.</strong> Complete privacy by design.
              </p>
            </div>
            <div className="data-item">
              <h3>Server Credentials</h3>
              <p>Your server passwords and API tokens are encrypted on your 
              device using hardware-backed secure storage (Android Keystore, iOS Keychain, 
              Windows DPAPI). They never leave your device.</p>
            </div>
          </div>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Wifi size={24} />
            <h2>Musly Connect & Local LAN Networking</h2>
          </div>
          <div className="data-grid">
            <div className="data-item">
              <h3>100% Peer-to-Peer LAN</h3>
              <p>Musly Connect communicates strictly over your local Wi-Fi network (UDP port 43882 / HTTP port 43883). No playback transfers, device names, or commands are ever routed through any external cloud server.</p>
              {/* Listening Party (BeatSync) temporarily disabled */}
            </div>
            <div className="data-item">
              <h3>Total User Control</h3>
              <p>Musly Connect can be completely toggled off in Settings at any time, shutting down all network sockets, beacons, and background discovery immediately.</p>
            </div>
          </div>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Share2 size={24} />
            <h2>Data Sharing</h2>
          </div>
          <div className="sharing-grid">
            <div className="sharing-item no">
              <UserX size={32} />
              <h3>We DO NOT Share:</h3>
              <ul>
                <li>Your music library</li>
                <li>Your listening history</li>
                <li>Your server credentials</li>
                <li>Your personal information</li>
                <li>Your IP address or device identifiers</li>
                <li>Any data with advertisers or data brokers</li>
              </ul>
            </div>
            <div className="sharing-item yes">
              <Eye size={32} />
              <h3>What We DO Share:</h3>
              <ul>
                <li><strong>Nothing.</strong> Your data stays on your device.</li>
              </ul>
              <p className="analytics-note">
                Optional services: LRCLIB (for public synced lyrics lookup) and Discord RPC (local playback status) communicate directly without transmitting personal identifiers.
              </p>
            </div>
          </div>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Trash2 size={24} />
            <h2>Your Rights</h2>
          </div>
          <div className="rights-list">
            <div className="right-item">
              <h3>Right to Control</h3>
              <p>You have absolute control over your data. All listening history, cache, and preferences can be reset locally at any time.</p>
            </div>
            <div className="right-item">
              <h3>Right to Deletion</h3>
              <p>Clearing the app storage or uninstalling the app permanently removes 100% of your local data.</p>
            </div>
            <div className="right-item">
              <h3>No Opt-In Required</h3>
              <p>You are private by default. No analytics toggles needed because zero tracking code exists.</p>
            </div>
            <div className="right-item">
              <h3>Right to Portability</h3>
              <p>Your music library belongs to you. Connect to any standard Subsonic, Navidrome, or Jellyfin server.</p>
            </div>
          </div>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Shield size={24} />
            <h2>Security Measures</h2>
          </div>
          <ul className="security-list">
            <li>Direct encrypted connections (HTTPS / TLS) to your personal media servers</li>
            <li>Hardware-backed credential encryption (Keychain, Keystore, Windows DPAPI)</li>
            <li>Origin validation and size limits on local network sockets to prevent web cross-origin exploits</li>
            <li>Zero intermediary servers — we do not host or operate servers that process your audio</li>
            <li>100% Open Source code — anyone can audit our privacy claims</li>
          </ul>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Mail size={24} />
            <h2>Contact Us</h2>
          </div>
          <p>
            Questions about privacy? Contact us:
          </p>
          <div className="contact-options">
            <a href="https://discord.gg/RrcFvFPdRU" className="contact-link">
              Discord Community
            </a>
            <a href="https://github.com/dddevid/Musly/issues" className="contact-link">
              GitHub Issues
            </a>
          </div>
        </section>

        <section className="privacy-section highlight">
          <div className="section-header">
            <Lock size={24} />
            <h2>Open Source Promise</h2>
          </div>
          <p>
            Musly is 100% open source. You can verify every line of code that handles your data:
          </p>
          <a 
            href="https://github.com/dddevid/Musly" 
            className="github-link"
            target="_blank"
            rel="noopener noreferrer"
          >
            View Source Code on GitHub →
          </a>
        </section>

        <footer className="privacy-footer">
          <p>Last updated: August 23, 2026</p>
          <p className="version">Musly v2.0.0</p>
        </footer>
      </div>
      
      <Footer onPrivacyClick={onBack} />
    </div>
  )
}

export default PrivacyPolicy
