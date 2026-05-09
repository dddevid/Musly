import { motion } from 'framer-motion'
import { Download, Github, Star, Smartphone, Monitor, Music2 } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import { useGithubRelease } from '../hooks/useGithubRelease'
import './Hero.css'

export default function Hero() {
    const { version, loading: vLoading } = useGithubRelease()

    const platforms = ['Android', 'iOS', 'Windows', 'macOS', 'Linux']

    return (
        <section className="hero">
            <div className="container hero-container">
                {/* ── Left content ── */}
                <div className="hero-content">
                    <FadeIn delay={0.05}>
                        <div className="hero-badge">
                            <Star size={12} fill="currentColor" />
                            <span>Best Navidrome Client 2026</span>
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.15}>
                        <h1 className="hero-title">
                            Your Music,<br />
                            <GradientText>Everywhere</GradientText>
                        </h1>
                    </FadeIn>

                    <FadeIn delay={0.25}>
                        <p className="hero-desc">
                            The ultimate <strong>Navidrome &amp; Subsonic client</strong> with an Apple Music-inspired interface. Stream your self-hosted library beautifully, on every device.
                        </p>
                    </FadeIn>

                    <FadeIn delay={0.35}>
                        <div className="hero-platforms">
                            {platforms.map(p => (
                                <span key={p} className="hero-platform">{p}</span>
                            ))}
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.45}>
                        <div className="hero-actions">
                            <motion.a
                                href="#download"
                                className="btn btn-primary"
                                whileHover={{ scale: 1.03 }}
                                whileTap={{ scale: 0.97 }}
                            >
                                <Download size={18} />
                                Download Free
                            </motion.a>
                            <motion.a
                                href="https://github.com/dddevid/Musly"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-secondary"
                                whileHover={{ scale: 1.03 }}
                                whileTap={{ scale: 0.97 }}
                            >
                                <Github size={18} />
                                View on GitHub
                            </motion.a>
                        </div>
                    </FadeIn>

                    <FadeIn delay={0.55}>
                        <div className="hero-stats">
                            <div className="hero-stat">
                                <span className="hero-stat-val">
                                    {vLoading ? '…' : (version ?? 'v1.0.12')}
                                </span>
                                <span className="hero-stat-label">Latest Release</span>
                            </div>
                            <div className="hero-stat-sep" />
                            <div className="hero-stat">
                                <span className="hero-stat-val">5+</span>
                                <span className="hero-stat-label">Platforms</span>
                            </div>
                            <div className="hero-stat-sep" />
                            <div className="hero-stat">
                                <span className="hero-stat-val">Free</span>
                                <span className="hero-stat-label">Open Source</span>
                            </div>
                        </div>
                    </FadeIn>
                </div>

                {/* ── Right: phone mockup ── */}
                <div className="hero-visual">
                    <motion.div
                        className="hero-phone-wrap"
                        initial={{ opacity: 0, y: 60 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.9, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
                    >
                        {/* Glow */}
                        <div className="hero-phone-glow" />

                        {/* Secondary phone (behind-left) */}
                        <div className="hero-phone hero-phone-secondary hero-phone-left">
                            <img
                                src="/screenshots/Screenshot_20260101_024726.png"
                                alt="Musly Home"
                                className="hero-phone-img"
                            />
                        </div>

                        {/* Main phone */}
                        <div className="hero-phone hero-phone-main">
                            <div className="hero-phone-notch" />
                            <img
                                src="/screenshots/Screenshot_20260101_024746.png"
                                alt="Musly Now Playing"
                                className="hero-phone-img"
                            />
                        </div>

                        {/* Secondary phone (behind-right) */}
                        <div className="hero-phone hero-phone-secondary hero-phone-right">
                            <img
                                src="/screenshots/Screenshot_20260101_024751.png"
                                alt="Musly Lyrics"
                                className="hero-phone-img"
                            />
                        </div>

                        {/* Floating now-playing card */}
                        <motion.div
                            className="hero-float-card"
                            animate={{ y: [0, -10, 0] }}
                            transition={{ duration: 3.5, repeat: Infinity, ease: 'easeInOut' }}
                        >
                            <div className="hero-float-icon">
                                <Music2 size={16} />
                            </div>
                            <div className="hero-float-text">
                                <span className="hero-float-title">Now Playing</span>
                                <span className="hero-float-sub">Apple Music-like UI</span>
                            </div>
                            <div className="hero-float-bars">
                                {[1, 2, 3, 4].map(i => (
                                    <div
                                        key={i}
                                        className="hero-float-bar"
                                        style={{ animationDelay: `${i * 0.15}s` }}
                                    />
                                ))}
                            </div>
                        </motion.div>

                        {/* Floating badge */}
                        <motion.div
                            className="hero-float-badge"
                            animate={{ y: [0, 8, 0] }}
                            transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
                        >
                            <Smartphone size={14} />
                            <span>5 Platforms</span>
                        </motion.div>
                    </motion.div>
                </div>
            </div>

            {/* Scroll hint */}
            <motion.div
                className="hero-scroll-hint"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 1.8 }}
            >
                <motion.div
                    className="hero-scroll-dot"
                    animate={{ y: [0, 10, 0] }}
                    transition={{ duration: 1.4, repeat: Infinity }}
                />
            </motion.div>
        </section>
    )
}
