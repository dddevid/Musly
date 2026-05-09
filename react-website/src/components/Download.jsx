import { motion } from 'framer-motion'
import { Download, Monitor, Smartphone, Github, ExternalLink, CheckCircle, Clock } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import { useGithubRelease } from '../hooks/useGithubRelease'
import './Download.css'

const platforms = [
    {
        name: 'Android',
        icon: Smartphone,
        status: 'available',
        badge: 'APK Direct',
        description: 'Android 6.0+',
        link: 'https://github.com/dddevid/Musly/releases/latest',
    },
    {
        name: 'Windows',
        icon: Monitor,
        status: 'available',
        badge: 'Installer',
        description: 'Windows 10/11',
        link: 'https://github.com/dddevid/Musly/releases/latest',
    },
    {
        name: 'iOS',
        icon: Smartphone,
        status: 'available',
        badge: 'IPA',
        description: 'iOS 14+',
        link: 'https://github.com/dddevid/Musly/releases/latest',
    },
    {
        name: 'macOS',
        icon: Monitor,
        status: 'available',
        badge: 'DMG',
        description: 'macOS 11+',
        link: 'https://github.com/dddevid/Musly/releases/latest',
    },
    {
        name: 'Linux',
        icon: Monitor,
        status: 'available',
        badge: 'AppImage / deb',
        description: 'Ubuntu, Arch, etc.',
        link: 'https://github.com/dddevid/Musly/releases/latest',
    },
]

export default function DownloadSection() {
    const { version, date, loading: vLoading } = useGithubRelease()

    return (
        <section id="download" className="download section">
            <div className="container">
                {/* Header */}
                <FadeIn className="dl-header">
                    <span className="section-tag">Download</span>
                    <h2 className="dl-title">
                        Get <GradientText>Musly</GradientText> Free
                    </h2>
                    <p className="dl-subtitle">
                        Open source &amp; completely free. Pick your platform and start streaming.
                    </p>
                </FadeIn>

                {/* Version pill */}
                {!vLoading && (
                    <FadeIn delay={0.1}>
                        <div className="dl-version">
                            <div className="dl-version-dot" />
                            <span className="dl-version-name">{version ?? 'v1.0.12'}</span>
                            <span className="dl-version-sep">·</span>
                            <span className="dl-version-date">{date ?? 'Latest release'}</span>
                        </div>
                    </FadeIn>
                )}

                {/* Platform grid */}
                <div className="dl-grid">
                    {platforms.map((p, i) => (
                        <FadeIn key={p.name} delay={0.1 + i * 0.05}>
                            <motion.a
                                href={p.link}
                                target="_blank"
                                rel="noopener noreferrer"
                                className={`dl-card dl-card--${p.status}`}
                                whileHover={{ scale: 1.02, y: -4 }}
                                whileTap={{ scale: 0.98 }}
                            >
                                <div className="dl-card-top">
                                    <div className="dl-card-icon">
                                        <p.icon size={26} />
                                    </div>
                                    {p.status === 'available' ? (
                                        <CheckCircle size={16} className="dl-card-status-icon dl-status-ok" />
                                    ) : (
                                        <Clock size={16} className="dl-card-status-icon dl-status-soon" />
                                    )}
                                </div>
                                <div className="dl-card-body">
                                    <h3 className="dl-card-name">{p.name}</h3>
                                    <p className="dl-card-sys">{p.description}</p>
                                    <span className={`dl-card-badge dl-badge--${p.status}`}>
                                        {p.status === 'available' ? <Download size={12} /> : <ExternalLink size={12} />}
                                        {p.badge}
                                    </span>
                                </div>
                            </motion.a>
                        </FadeIn>
                    ))}
                </div>

                {/* GitHub CTA */}
                <FadeIn delay={0.4}>
                    <div className="dl-github">
                        <div className="dl-github-left">
                            <Github size={28} className="dl-github-icon" />
                            <div>
                                <h3 className="dl-github-title">Open Source on GitHub</h3>
                                <p className="dl-github-desc">Browse the source, file issues, and contribute to Musly.</p>
                            </div>
                        </div>
                        <a
                            href="https://github.com/dddevid/Musly"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="btn btn-secondary"
                        >
                            <Github size={17} />
                            View on GitHub
                        </a>
                    </div>
                </FadeIn>
            </div>
        </section>
    )
}
