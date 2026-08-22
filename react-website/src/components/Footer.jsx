import { Github, MessageCircle, Coffee, Heart, ExternalLink } from 'lucide-react'
import logo from '../assets/logo.png'
import './Footer.css'

const sections = {
    product: {
        title: 'Product',
        links: [
            { label: 'Features', href: '#features' },
            { label: 'Screenshots', href: '#screenshots' },
            { label: 'Download', href: '#download' },
            { label: 'Changelog', href: 'https://github.com/dddevid/Musly/blob/master/CHANGELOG.md', ext: true },
        ]
    },
    resources: {
        title: 'Resources',
        links: [
            { label: 'GitHub', href: 'https://github.com/dddevid/Musly', ext: true },
            { label: 'Issues', href: 'https://github.com/dddevid/Musly/issues', ext: true },
            { label: 'Releases', href: 'https://github.com/dddevid/Musly/releases', ext: true },
            { label: 'License', href: 'https://github.com/dddevid/Musly/blob/master/LICENSE', ext: true },
        ]
    },
    community: {
        title: 'Community',
        links: [
            { label: 'Discord', href: 'https://discord.gg/k9FqpbT65M', ext: true },
            { label: 'Buy Me a Coffee', href: 'https://buymeacoffee.com/devidd', ext: true },
        ]
    },
    compatible: {
        title: 'Compatible With',
        links: [
            { label: 'Navidrome', href: 'https://www.navidrome.org/', ext: true },
            { label: 'Subsonic', href: 'http://www.subsonic.org/', ext: true },
            { label: 'Airsonic', href: 'https://airsonic.github.io/', ext: true },
            { label: 'Gonic', href: 'https://github.com/sentriz/gonic', ext: true },
        ]
    },
}

export default function Footer({ onPrivacyClick }) {
    return (
        <footer className="footer">
            <div className="container">
                {/* Divider */}
                <div className="footer-divider" />

                {/* Main */}
                <div className="footer-main">
                    {/* Brand */}
                    <div className="footer-brand">
                        <a href="#" className="footer-logo">
                            <img src={logo} alt="Musly" className="footer-logo-img" />
                            <span className="footer-logo-name">Musly</span>
                        </a>
                        <p className="footer-tagline">
                            The best free Navidrome &amp; Subsonic client with an modern and elegant interface.
                        </p>
                        <div className="footer-socials">
                            <a href="https://github.com/dddevid/Musly" target="_blank" rel="noopener noreferrer" className="footer-social" aria-label="GitHub">
                                <Github size={18} />
                            </a>
                            <a href="https://discord.gg/k9FqpbT65M" target="_blank" rel="noopener noreferrer" className="footer-social" aria-label="Discord">
                                <MessageCircle size={18} />
                            </a>
                            <a href="https://buymeacoffee.com/devidd" target="_blank" rel="noopener noreferrer" className="footer-social" aria-label="Buy Me a Coffee">
                                <Coffee size={18} />
                            </a>
                        </div>
                    </div>

                    {/* Links grid */}
                    <div className="footer-links">
                        {Object.values(sections).map(sec => (
                            <div key={sec.title} className="footer-col">
                                <h5 className="footer-col-title">{sec.title}</h5>
                                <ul className="footer-col-list">
                                    {sec.links.map(link => (
                                        <li key={link.label}>
                                            <a
                                                href={link.href}
                                                target={link.ext ? '_blank' : undefined}
                                                rel={link.ext ? 'noopener noreferrer' : undefined}
                                                className="footer-link"
                                            >
                                                {link.label}
                                                {link.ext && <ExternalLink size={11} />}
                                            </a>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Bottom bar */}
                <div className="footer-bottom">
                    <p className="footer-copy">
                        © {new Date().getFullYear()} Musly · CC BY-NC-SA 4.0 License
                    </p>
                    <div className="footer-legal">
                        <button onClick={onPrivacyClick} className="footer-legal-link">
                            Privacy Policy
                        </button>
                    </div>
                    <p className="footer-made">
                        Made with <Heart size={13} fill="#ff2d55" color="#ff2d55" /> in Italy 🇮🇹 by an Albanian developer 🇦🇱
                    </p>
                </div>
            </div>
        </footer>
    )
}
