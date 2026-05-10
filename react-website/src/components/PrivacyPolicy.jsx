import { useEffect } from 'react'
import { ArrowLeft, Shield, Lock, Eye, Database, Share2, UserX, Trash2, Mail } from 'lucide-react'
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
            <h2>What Data We Collect</h2>
          </div>
          <div className="data-grid">
            <div className="data-item">
              <h3>Music Library</h3>
              <p>Your music library metadata (song titles, artists, albums) is stored 
              locally on your device or on your personal Navidrome/Subsonic server. 
              We never access this data.</p>
            </div>
            <div className="data-item">
              <h3>Anonymous Analytics</h3>
              <p>With your consent, we collect anonymous usage statistics including:</p>
              <ul>
                <li>App crashes (to fix bugs)</li>
                <li>Feature usage (to improve the app)</li>
                <li>Country-level location (for regional insights)</li>
                <li>Monthly active users count</li>
              </ul>
              <p className="no-identifiers">
                <strong>No advertising IDs.</strong> No personal identifiers. 
                Completely anonymous.
              </p>
            </div>
            <div className="data-item">
              <h3>Server Credentials</h3>
              <p>Your Navidrome/Subsonic server credentials are stored securely on your 
              device using platform-specific secure storage. We never see or store 
              your passwords.</p>
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
                <li>Your email address</li>
                <li>Any data with advertisers</li>
                <li>Any data with data brokers</li>
              </ul>
            </div>
            <div className="sharing-item yes">
              <Eye size={32} />
              <h3>What We DO Share:</h3>
              <ul>
                <li>Nothing. Your data stays with you.</li>
              </ul>
              <p className="analytics-note">
                Anonymous analytics (if enabled) are sent to our self-hosted Countly 
                server. This data cannot identify you personally.
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
              <h3>Right to Access</h3>
              <p>You can request a copy of all data we have about you (it's minimal and anonymous).</p>
            </div>
            <div className="right-item">
              <h3>Right to Deletion</h3>
              <p>Contact us to delete any anonymous analytics data associated with your device.</p>
            </div>
            <div className="right-item">
              <h3>Right to Opt-Out</h3>
              <p>Disable analytics anytime in Settings → Analytics & Privacy.</p>
            </div>
            <div className="right-item">
              <h3>Right to Portability</h3>
              <p>Your music library is yours. Export it anytime from the app.</p>
            </div>
          </div>
        </section>

        <section className="privacy-section">
          <div className="section-header">
            <Shield size={24} />
            <h2>Security Measures</h2>
          </div>
          <ul className="security-list">
            <li>All server connections use HTTPS encryption</li>
            <li>Local credentials stored in platform secure storage (Keychain/Keystore)</li>
            <li>No data stored on our servers except anonymous analytics</li>
            <li>Open source code - anyone can audit our privacy claims</li>
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
          <p>Last updated: May 2, 2026</p>
          <p className="version">Musly v1.0.13</p>
        </footer>
      </div>
      
      <Footer onPrivacyClick={onBack} />
    </div>
  )
}

export default PrivacyPolicy
