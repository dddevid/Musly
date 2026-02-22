import { motion } from 'framer-motion'
import { Download, Apple, Monitor, Smartphone, ExternalLink, Github } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import { useGithubRelease } from '../hooks/useGithubRelease'
import './Download.css'

const platforms = [
    {
        name: 'Android',
        icon: Smartphone,
        status: 'available',
        description: 'Download APK',
        link: 'https://github.com/dddevid/Musly/releases/latest'
    },
    {
        name: 'Windows',
        icon: Monitor,
        status: 'available',
        description: 'Download EXE',
        link: 'https://github.com/dddevid/Musly/releases/latest'
    },
    {
        name: 'iOS',
        icon: Apple,
        status: 'build',
        description: 'Build from source',
        link: 'https://github.com/dddevid/Musly'
    },
    {
        name: 'macOS',
        icon: Apple,
        status: 'build',
        description: 'Build from source',
        link: 'https://github.com/dddevid/Musly'
    },
    {
        name: 'Linux',
        icon: Monitor,
        status: 'build',
        description: 'Build from source',
        link: 'https://github.com/dddevid/Musly'
    }
]

export default function DownloadSection() {
    const { version, date, loading: vLoading } = useGithubRelease()

    return (
        <section id="download" className="download section">
            <div className="container">
                {/* Header */}
                <FadeIn className="download-header">
                    <span className="download-badge">Download</span>
                    <h2 className="download-title">
                        Get <GradientText>Musly</GradientText> Today
                    </h2>
                    <p className="download-subtitle">
                        Free and open source. Download for your platform and start streaming your music.
                    </p>
                </FadeIn>

                {/* Version Info */}
                <FadeIn delay={0.1}>
                    <div className="download-version">
                        <div className="download-version-badge">
                            <span className="download-version-number">
                                {vLoading ? '\u2026' : (version ?? 'v1.0.7')}
                            </span>
                            <span className="download-version-label">Latest Release</span>
                        </div>
                        {date && <p className="download-version-date">Released {date}</p>}
                    </div>
                </FadeIn>

                {/* Platform Cards */}
                <div className="download-platforms">
                    {platforms.map((platform, index) => (
                        <FadeIn key={platform.name} delay={0.1 + index * 0.05}>
                            <motion.a
                                href={platform.link}
                                target="_blank"
                                rel="noopener noreferrer"
                                className={`download-card ${platform.status}`}
                                whileHover={{ scale: 1.02, y: -4 }}
                                whileTap={{ scale: 0.98 }}
                            >
                                <div className="download-card-icon">
                                    <platform.icon size={28} />
                                </div>
                                <div className="download-card-content">
                                    <h3 className="download-card-name">{platform.name}</h3>
                                    <p className="download-card-description">{platform.description}</p>
                                </div>
                                {platform.status === 'available' ? (
                                    <Download size={20} className="download-card-action" />
                                ) : (
                                    <ExternalLink size={20} className="download-card-action" />
                                )}
                            </motion.a>
                        </FadeIn>
                    ))}
                </div>

                {/* GitHub CTA */}
                <FadeIn delay={0.4}>
                    <div className="download-github">
                        <div className="download-github-content">
                            <Github size={32} />
                            <div>
                                <h3>Open Source</h3>
                                <p>View source code, contribute, and report issues on GitHub</p>
                            </div>
                        </div>
                        <a
                            href="https://github.com/dddevid/Musly"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="btn btn-secondary"
                        >
                            <Github size={18} />
                            View on GitHub
                        </a>
                    </div>
                </FadeIn>
            </div>
        </section>
    )
}
