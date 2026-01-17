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
import SpotlightCard from './effects/SpotlightCard'
import GradientText from './effects/GradientText'
import './Features.css'

const features = [
    {
        icon: Music,
        title: 'Apple Music UI',
        description: 'Beautiful, modern interface inspired by Apple Music with smooth animations and intuitive navigation.'
    },
    {
        icon: Mic2,
        title: 'Synced Lyrics',
        description: 'Time-synced lyrics with blur effects and glow animations. Desktop fullscreen mode included.'
    },
    {
        icon: Sliders,
        title: 'Premium Equalizer',
        description: '10-band equalizer with presets (Rock, Pop, Jazz, Bass Boost) and custom preset saving.'
    },
    {
        icon: Car,
        title: 'Android Auto',
        description: 'Full Android Auto integration for safe music control while driving.'
    },
    {
        icon: WifiOff,
        title: 'Offline Mode',
        description: 'Download your favorite songs and playlists for offline listening. Automatic fallback when server is unreachable.'
    },
    {
        icon: Smartphone,
        title: 'Cross-Platform',
        description: 'Available on Android, iOS, Windows, macOS, and Linux. Your music everywhere.'
    },
    {
        icon: ListMusic,
        title: 'Smart Playlists',
        description: 'Create, manage, and sync playlists with your Subsonic server. Full playlist management.'
    },
    {
        icon: Radio,
        title: 'Internet Radio',
        description: 'Stream internet radio stations from your server. Support for various streaming formats.'
    },
    {
        icon: Shuffle,
        title: 'Auto-DJ',
        description: 'Smart queue that automatically adds similar songs when your queue ends.'
    },
    {
        icon: Heart,
        title: 'Star Ratings',
        description: 'Rate your songs with 1-5 stars. Synced with your Subsonic server.'
    },
    {
        icon: Volume2,
        title: 'ReplayGain',
        description: 'Automatic volume normalization for consistent playback across all tracks.'
    },
    {
        icon: Sparkles,
        title: 'Smart Recommendations',
        description: 'Personalized mixes, "For You" feed, and listening history based on your taste.'
    }
]

export default function Features() {
    return (
        <section id="features" className="features section">
            <div className="container">
                {/* Header */}
                <FadeIn className="features-header">
                    <span className="features-badge">Features</span>
                    <h2 className="features-title">
                        Everything You Need to{' '}
                        <GradientText>Enjoy Music</GradientText>
                    </h2>
                    <p className="features-subtitle">
                        Musly comes packed with features designed to give you the best music streaming experience from your self-hosted server.
                    </p>
                </FadeIn>

                {/* Grid */}
                <div className="features-grid">
                    {features.map((feature, index) => (
                        <FadeIn key={feature.title} delay={index * 0.05}>
                            <SpotlightCard className="feature-card">
                                <div className="feature-icon">
                                    <feature.icon size={24} />
                                </div>
                                <h3 className="feature-title">{feature.title}</h3>
                                <p className="feature-description">{feature.description}</p>
                            </SpotlightCard>
                        </FadeIn>
                    ))}
                </div>
            </div>
        </section>
    )
}
