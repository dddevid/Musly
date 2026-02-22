import { Github, MessageCircle, Coffee, Heart, ExternalLink } from 'lucide-react'
import logo from '../assets/logo.png'
import './Footer.css'

export default function Footer() {
    const currentYear = new Date().getFullYear()

    const links = {
        product: [
            { name: 'Features', href: '#features' },
            { name: 'Screenshots', href: '#screenshots' },
            { name: 'Download', href: '#download' },
            { name: 'Changelog', href: 'https://github.com/dddevid/Musly/blob/master/CHANGELOG.md', external: true }
        ],
        resources: [
            { name: 'Documentation', href: 'https://github.com/dddevid/Musly/blob/main/DOCUMENTATION.md', external: true },
            { name: 'GitHub', href: 'https://github.com/dddevid/Musly', external: true },
            { name: 'Issues', href: 'https://github.com/dddevid/Musly/issues', external: true },
            { name: 'Releases', href: 'https://github.com/dddevid/Musly/releases', external: true }
        ],
        community: [
            { name: 'Discord', href: 'https://discord.gg/k9FqpbT65M', external: true },
            { name: 'Buy Me a Coffee', href: 'https://buymeacoffee.com/devidd', external: true }
        ],
        compatible: [
            { name: 'Navidrome', href: 'https://www.navidrome.org/', external: true },
            { name: 'Subsonic', href: 'http://www.subsonic.org/', external: true },
            { name: 'Airsonic', href: 'https://airsonic.github.io/', external: true },
            { name: 'Gonic', href: 'https://github.com/sentriz/gonic', external: true }
        ]
    }

    return (
        <footer className="footer">
            <div className="container">
                {/* Main Footer */}
                <div className="footer-main">
                    {/* Brand */}
                    <div className="footer-brand">
                        <a href="#" className="footer-logo">
                            <img src={logo} alt="Musly Logo" className="footer-logo-img" />
                            <span className="footer-logo-text">Musly</span>
                        </a>
                        <p className="footer-description">
                            The best free Navidrome client and Subsonic music player with a beautiful Apple Music-inspired interface.
                        </p>
                        <div className="footer-socials">
                            <a
                                href="https://github.com/dddevid/Musly"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="footer-social"
                                aria-label="GitHub"
                            >
                                <Github size={20} />
                            </a>
                            <a
                                href="https://discord.gg/k9FqpbT65M"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="footer-social"
                                aria-label="Discord"
                            >
                                <MessageCircle size={20} />
                            </a>
                            <a
                                href="https://buymeacoffee.com/devidd"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="footer-social"
                                aria-label="Buy Me a Coffee"
                            >
                                <Coffee size={20} />
                            </a>
                        </div>
                    </div>

                    {/* Links */}
                    <div className="footer-links">
                        <div className="footer-column">
                            <h4 className="footer-column-title">Product</h4>
                            <ul className="footer-column-list">
                                {links.product.map((link) => (
                                    <li key={link.name}>
                                        <a
                                            href={link.href}
                                            target={link.external ? '_blank' : undefined}
                                            rel={link.external ? 'noopener noreferrer' : undefined}
                                            className="footer-link"
                                        >
                                            {link.name}
                                            {link.external && <ExternalLink size={12} />}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        <div className="footer-column">
                            <h4 className="footer-column-title">Resources</h4>
                            <ul className="footer-column-list">
                                {links.resources.map((link) => (
                                    <li key={link.name}>
                                        <a
                                            href={link.href}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="footer-link"
                                        >
                                            {link.name}
                                            <ExternalLink size={12} />
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        <div className="footer-column">
                            <h4 className="footer-column-title">Community</h4>
                            <ul className="footer-column-list">
                                {links.community.map((link) => (
                                    <li key={link.name}>
                                        <a
                                            href={link.href}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="footer-link"
                                        >
                                            {link.name}
                                            <ExternalLink size={12} />
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        <div className="footer-column">
                            <h4 className="footer-column-title">Compatible With</h4>
                            <ul className="footer-column-list">
                                {links.compatible.map((link) => (
                                    <li key={link.name}>
                                        <a
                                            href={link.href}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="footer-link"
                                        >
                                            {link.name}
                                            <ExternalLink size={12} />
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </div>

                {/* Bottom */}
                <div className="footer-bottom">
                    <div className="footer-copyright">
                        <p>© {currentYear} Musly. Open source under CC BY-NC-SA 4.0 License.</p>
                    </div>
                    <div className="footer-made">
                        <span>Made with</span>
                        <Heart size={14} fill="#fa243c" color="#fa243c" />
                        <span>in Italy 🇮🇹 by an Albanian developer 🇦🇱</span>
                    </div>
                </div>
            </div>
        </footer>
    )
}
