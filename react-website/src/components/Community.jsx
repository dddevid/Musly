import { motion } from 'framer-motion'
import { MessageCircle, Coffee, Heart, Github, Bitcoin } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import SpotlightCard from './effects/SpotlightCard'
import GradientText from './effects/GradientText'
import './Community.css'

export default function Community() {
    return (
        <section className="community section">
            <div className="container">
                {/* Header */}
                <FadeIn className="community-header">
                    <span className="community-badge">Community</span>
                    <h2 className="community-title">
                        Join the <GradientText>Musly</GradientText> Community
                    </h2>
                    <p className="community-subtitle">
                        Connect with other users, get support, and help shape the future of Musly.
                    </p>
                </FadeIn>

                {/* Cards */}
                <div className="community-cards">
                    {/* Discord */}
                    <FadeIn delay={0.1}>
                        <SpotlightCard className="community-card discord">
                            <div className="community-card-icon discord-icon">
                                <MessageCircle size={28} />
                            </div>
                            <h3 className="community-card-title">Discord Community</h3>
                            <p className="community-card-description">
                                Join our Discord server to chat with other users, get help, and stay updated on new features.
                            </p>
                            <motion.a
                                href="https://discord.gg/k9FqpbT65M"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-discord"
                                whileHover={{ scale: 1.02 }}
                                whileTap={{ scale: 0.98 }}
                            >
                                <MessageCircle size={18} />
                                Join Discord
                            </motion.a>
                        </SpotlightCard>
                    </FadeIn>

                    {/* Support */}
                    <FadeIn delay={0.2}>
                        <SpotlightCard className="community-card support">
                            <div className="community-card-icon support-icon">
                                <Coffee size={28} />
                            </div>
                            <h3 className="community-card-title">Support Development</h3>
                            <p className="community-card-description">
                                If you enjoy using Musly, consider supporting its development. Every contribution helps!
                            </p>
                            <div className="community-support-buttons">
                                <motion.a
                                    href="https://buymeacoffee.com/devidd"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="btn btn-coffee"
                                    whileHover={{ scale: 1.02 }}
                                    whileTap={{ scale: 0.98 }}
                                >
                                    <Coffee size={18} />
                                    Buy Me a Coffee
                                </motion.a>
                            </div>
                            <div className="community-crypto">
                                <p className="community-crypto-label">Or donate with crypto:</p>
                                <div className="community-crypto-options">
                                    <div className="crypto-option">
                                        <Bitcoin size={16} />
                                        <span>Bitcoin</span>
                                    </div>
                                    <div className="crypto-option">
                                        <span className="crypto-sol">◎</span>
                                        <span>Solana</span>
                                    </div>
                                </div>
                            </div>
                        </SpotlightCard>
                    </FadeIn>

                    {/* Contribute */}
                    <FadeIn delay={0.3}>
                        <SpotlightCard className="community-card contribute">
                            <div className="community-card-icon contribute-icon">
                                <Heart size={28} />
                            </div>
                            <h3 className="community-card-title">Contribute</h3>
                            <p className="community-card-description">
                                Musly is open source! Report bugs, suggest features, or contribute code on GitHub.
                            </p>
                            <motion.a
                                href="https://github.com/dddevid/Musly"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-secondary"
                                whileHover={{ scale: 1.02 }}
                                whileTap={{ scale: 0.98 }}
                            >
                                <Github size={18} />
                                View on GitHub
                            </motion.a>
                        </SpotlightCard>
                    </FadeIn>
                </div>
            </div>
        </section>
    )
}
