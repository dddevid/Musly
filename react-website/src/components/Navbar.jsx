import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Menu, X, Github, ExternalLink } from 'lucide-react'
import logo from '../assets/logo.png'
import './Navbar.css'

export default function Navbar() {
    const [isScrolled, setIsScrolled] = useState(false)
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    const navLinks = [
        { name: 'Features', href: '#features' },
        { name: 'Screenshots', href: '#screenshots' },
        { name: 'Download', href: '#download' },
    ]

    return (
        <>
            <motion.nav
                className={`navbar ${isScrolled ? 'scrolled' : ''}`}
                initial={{ y: -100 }}
                animate={{ y: 0 }}
                transition={{ duration: 0.6, ease: [0.25, 0.1, 0.25, 1] }}
            >
                <div className="navbar-container container">
                    {/* Logo */}
                    <a href="#" className="navbar-logo">
                        <img src={logo} alt="Musly Logo" className="navbar-logo-img" />
                        <span className="navbar-logo-text">Musly</span>
                    </a>

                    {/* Desktop Navigation */}
                    <div className="navbar-links">
                        {navLinks.map((link) => (
                            <a key={link.name} href={link.href} className="navbar-link">
                                {link.name}
                            </a>
                        ))}
                    </div>

                    {/* Desktop Actions */}
                    <div className="navbar-actions">
                        <a
                            href="https://github.com/dddevid/Musly"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="navbar-github"
                        >
                            <Github size={20} />
                            <span>GitHub</span>
                        </a>
                        <a href="#download" className="btn btn-primary navbar-cta">
                            Download
                            <ExternalLink size={16} />
                        </a>
                    </div>

                    {/* Mobile Menu Button */}
                    <button
                        className="navbar-mobile-toggle"
                        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                        aria-label="Toggle menu"
                    >
                        {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>
                </div>
            </motion.nav>

            {/* Mobile Menu */}
            <AnimatePresence>
                {isMobileMenuOpen && (
                    <motion.div
                        className="navbar-mobile-menu"
                        initial={{ opacity: 0, y: -20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        transition={{ duration: 0.3 }}
                    >
                        <div className="navbar-mobile-links">
                            {navLinks.map((link, index) => (
                                <motion.a
                                    key={link.name}
                                    href={link.href}
                                    className="navbar-mobile-link"
                                    initial={{ opacity: 0, x: -20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    transition={{ delay: index * 0.1 }}
                                    onClick={() => setIsMobileMenuOpen(false)}
                                >
                                    {link.name}
                                </motion.a>
                            ))}
                            <motion.a
                                href="https://github.com/dddevid/Musly"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="navbar-mobile-link"
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: 0.3 }}
                            >
                                <Github size={20} />
                                GitHub
                            </motion.a>
                            <motion.a
                                href="#download"
                                className="btn btn-primary navbar-mobile-cta"
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: 0.4 }}
                                onClick={() => setIsMobileMenuOpen(false)}
                            >
                                Download Now
                            </motion.a>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </>
    )
}
