import { motion } from 'framer-motion'
import { Download, Play, Star, Smartphone, Monitor } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import './Hero.css'

export default function Hero() {
    return (
        <section className="hero section">
            <div className="container hero-container">
                {/* Content */}
                <div className="hero-content">
                    <FadeIn delay={0.1}>
                        <div className="hero-badge">
                            <Star size={14} fill="currentColor" />
                            <span>Best Navidrome Client 2026</span>
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.2}>
                        <h1 className="hero-title">
                            Your Music,{' '}
                            <GradientText>Everywhere</GradientText>
                        </h1>
                    </FadeIn>

                    <FadeIn delay={0.3}>
                        <p className="hero-description">
                            Musly is the ultimate <strong>Navidrome client</strong> and <strong>Subsonic music player</strong> with a beautiful Apple Music-inspired interface. Stream your self-hosted music library on any device.
                        </p>
                    </FadeIn>

                    <FadeIn delay={0.4}>
                        <div className="hero-platforms">
                            <div className="hero-platform">
                                <Smartphone size={16} />
                                <span>Android</span>
                            </div>
                            <div className="hero-platform">
                                <Smartphone size={16} />
                                <span>iOS</span>
                            </div>
                            <div className="hero-platform">
                                <Monitor size={16} />
                                <span>Windows</span>
                            </div>
                            <div className="hero-platform">
                                <Monitor size={16} />
                                <span>macOS</span>
                            </div>
                            <div className="hero-platform">
                                <Monitor size={16} />
                                <span>Linux</span>
                            </div>
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.5}>
                        <div className="hero-actions">
                            <a href="#download" className="btn btn-primary hero-btn">
                                <Download size={20} />
                                Download Free
                            </a>
                            <a
                                href="https://github.com/dddevid/Musly"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-secondary hero-btn"
                            >
                                <Play size={20} />
                                View on GitHub
                            </a>
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.6}>
                        <div className="hero-stats">
                            <div className="hero-stat">
                                <span className="hero-stat-value">v1.0.6</span>
                                <span className="hero-stat-label">Latest Version</span>
                            </div>
                            <div className="hero-stat-divider" />
                            <div className="hero-stat">
                                <span className="hero-stat-value">5</span>
                                <span className="hero-stat-label">Platforms</span>
                            </div>
                            <div className="hero-stat-divider" />
                            <div className="hero-stat">
                                <span className="hero-stat-value">100%</span>
                                <span className="hero-stat-label">Free & Open Source</span>
                            </div>
                        </div>
                    </FadeIn>
                </div>

                {/* Phone Mockups */}
                <div className="hero-mockups">
                    <motion.div
                        className="hero-phone hero-phone-main"
                        initial={{ opacity: 0, y: 60, rotateY: -15 }}
                        animate={{ opacity: 1, y: 0, rotateY: 0 }}
                        transition={{ duration: 0.8, delay: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
                    >
                        <div className="hero-phone-frame">
                            <img
                                src="/screenshots/Screenshot_20260101_024746.png"
                                alt="Musly Now Playing Screen"
                                className="hero-phone-screen"
                            />
                        </div>
                        <div className="hero-phone-glow" />
                    </motion.div>

                    <motion.div
                        className="hero-phone hero-phone-left"
                        initial={{ opacity: 0, x: -40, y: 40 }}
                        animate={{ opacity: 1, x: 0, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.5, ease: [0.25, 0.1, 0.25, 1] }}
                    >
                        <div className="hero-phone-frame">
                            <img
                                src="/screenshots/Screenshot_20260101_024726.png"
                                alt="Musly Home Screen"
                                className="hero-phone-screen"
                            />
                        </div>
                    </motion.div>

                    <motion.div
                        className="hero-phone hero-phone-right"
                        initial={{ opacity: 0, x: 40, y: 40 }}
                        animate={{ opacity: 1, x: 0, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.6, ease: [0.25, 0.1, 0.25, 1] }}
                    >
                        <div className="hero-phone-frame">
                            <img
                                src="/screenshots/Screenshot_20260101_024751.png"
                                alt="Musly Lyrics Screen"
                                className="hero-phone-screen"
                            />
                        </div>
                    </motion.div>
                </div>
            </div>

            {/* Scroll Indicator */}
            <motion.div
                className="hero-scroll"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 1.5 }}
            >
                <motion.div
                    className="hero-scroll-icon"
                    animate={{ y: [0, 8, 0] }}
                    transition={{ duration: 1.5, repeat: Infinity }}
                />
                <span>Scroll to explore</span>
            </motion.div>
        </section>
    )
}
