import {
    Music,
    Mic2,
    Sliders,
    Car,
    WifiOff,
    Smartphone,
    ListMusic,
    Radio,
    Shuffle,
    Heart,
    Volume2,
    Sparkles
} from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import './Features.css'

// bento: size can be 'wide' (spans 2 cols), 'tall', or 'normal'
const features = [
    {
        icon: Music,
        title: 'Modern Music Player UI',
        description: 'A beautiful, modern interface inspired by Musly — smooth animations, intuitive navigation, and a premium feel on every screen.',
        size: 'wide',
        accent: '#ff2d55',
    },
    {
        icon: Mic2,
        title: 'Synced Lyrics',
        description: 'Time-synced lyrics with blur and glow effects. Desktop fullscreen mode included.',
        size: 'normal',
        accent: '#bf5af2',
    },
    {
        icon: Sliders,
        title: 'Premium Equalizer',
        description: '10-band EQ with presets and custom save.',
        size: 'normal',
        accent: '#ff9f0a',
    },
    {
        icon: Car,
        title: 'Android Auto',
        description: 'Full Android Auto integration for safe in-car control.',
        size: 'normal',
        accent: '#30d158',
    },
    {
        icon: WifiOff,
        title: 'Offline Mode',
        description: 'Download songs & playlists for offline listening with automatic server fallback.',
        size: 'wide',
        accent: '#0a84ff',
    },
    {
        icon: Smartphone,
        title: 'Cross-Platform',
        description: 'Android, iOS, Windows, macOS & Linux — your music, everywhere.',
        size: 'normal',
        accent: '#ff375f',
    },
    {
        icon: ListMusic,
        title: 'Smart Playlists',
        description: 'Create, manage and sync playlists with your Subsonic server.',
        size: 'normal',
        accent: '#ffd60a',
    },
    {
        icon: Radio,
        title: 'Internet Radio',
        description: 'Stream internet radio stations from your server in multiple formats.',
        size: 'normal',
        accent: '#64d2ff',
    },
    {
        icon: Shuffle,
        title: 'Auto-DJ',
        description: 'Smart queue that adds similar songs when your list ends.',
        size: 'normal',
        accent: '#ff6961',
    },
    {
        icon: Heart,
        title: 'Star Ratings',
        description: 'Rate songs 1-5 stars, synced with your server.',
        size: 'normal',
        accent: '#ff375f',
    },
    {
        icon: Volume2,
        title: 'ReplayGain',
        description: 'Automatic volume normalisation across all tracks.',
        size: 'normal',
        accent: '#30d158',
    },
    {
        icon: Sparkles,
        title: 'Smart Mixes',
        description: 'Personalised mixes and a "For You" feed based on your taste.',
        size: 'normal',
        accent: '#bf5af2',
    },
]

export default function Features() {
    return (
        <section id="features" className="features section">
            <div className="container">
                {/* Header */}
                <FadeIn className="features-header">
                    <span className="section-tag">Features</span>
                    <h2 className="features-title">
                        Everything You Need to{' '}
                        <GradientText>Enjoy Music</GradientText>
                    </h2>
                    <p className="features-subtitle">
                        Musly is packed with features to give you the best self-hosted music experience.
                    </p>
                </FadeIn>

                {/* Bento Grid */}
                <div className="features-bento">
                    {features.map((feature, i) => (
                        <FadeIn key={feature.title} delay={i * 0.04} className={`feat-cell feat-cell--${feature.size}`}>
                            <div className="feat-card">
                                <div
                                    className="feat-icon"
                                    style={{ background: `${feature.accent}22`, color: feature.accent }}
                                >
                                    <feature.icon size={22} />
                                </div>
                                <div className="feat-content">
                                    <h3 className="feat-title">{feature.title}</h3>
                                    <p className="feat-desc">{feature.description}</p>
                                </div>
                                <div
                                    className="feat-accent-line"
                                    style={{ background: feature.accent }}
                                />
                            </div>
                        </FadeIn>
                    ))}
                </div>
            </div>
        </section>
    )
}
