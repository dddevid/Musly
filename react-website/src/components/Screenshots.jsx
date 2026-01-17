import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import FadeIn from './effects/FadeIn'
import GradientText from './effects/GradientText'
import './Screenshots.css'

const screenshots = [
    {
        src: '/screenshots/Screenshot_20260101_024726.png',
        alt: 'Musly Home Screen',
        title: 'Home Screen',
        description: 'Recently played, playlists, and quick access to your library'
    },
    {
        src: '/screenshots/Screenshot_20260101_024746.png',
        alt: 'Musly Now Playing',
        title: 'Now Playing',
        description: 'Full-featured player with album art and controls'
    },
    {
        src: '/screenshots/Screenshot_20260101_024751.png',
        alt: 'Musly Lyrics View',
        title: 'Synced Lyrics',
        description: 'Time-synced lyrics with blur and glow effects'
    },
    {
        src: '/screenshots/Screenshot_20260101_024803.png',
        alt: 'Musly Login Screen',
        title: 'Login Screen',
        description: 'Connect to your Subsonic server easily'
    }
]

export default function Screenshots() {
    const [currentIndex, setCurrentIndex] = useState(0)

    const nextSlide = () => {
        setCurrentIndex((prev) => (prev + 1) % screenshots.length)
    }

    const prevSlide = () => {
        setCurrentIndex((prev) => (prev - 1 + screenshots.length) % screenshots.length)
    }

    return (
        <section id="screenshots" className="screenshots section">
            <div className="container">
                {/* Header */}
                <FadeIn className="screenshots-header">
                    <span className="screenshots-badge">Screenshots</span>
                    <h2 className="screenshots-title">
                        See <GradientText>Musly</GradientText> in Action
                    </h2>
                    <p className="screenshots-subtitle">
                        A beautiful, intuitive interface designed to make your music experience seamless.
                    </p>
                </FadeIn>

                {/* Gallery */}
                <FadeIn delay={0.2}>
                    <div className="screenshots-gallery">
                        {/* Main Display */}
                        <div className="screenshots-display">
                            <AnimatePresence mode="wait">
                                <motion.div
                                    key={currentIndex}
                                    className="screenshot-main"
                                    initial={{ opacity: 0, scale: 0.9 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    exit={{ opacity: 0, scale: 0.9 }}
                                    transition={{ duration: 0.4 }}
                                >
                                    <div className="screenshot-phone">
                                        <img
                                            src={screenshots[currentIndex].src}
                                            alt={screenshots[currentIndex].alt}
                                            className="screenshot-image"
                                        />
                                    </div>
                                    <div className="screenshot-glow" />
                                </motion.div>
                            </AnimatePresence>

                            {/* Navigation Arrows */}
                            <button className="screenshot-nav screenshot-nav-prev" onClick={prevSlide}>
                                <ChevronLeft size={24} />
                            </button>
                            <button className="screenshot-nav screenshot-nav-next" onClick={nextSlide}>
                                <ChevronRight size={24} />
                            </button>
                        </div>

                        {/* Info */}
                        <AnimatePresence mode="wait">
                            <motion.div
                                key={currentIndex}
                                className="screenshot-info"
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                exit={{ opacity: 0, y: -20 }}
                                transition={{ duration: 0.3 }}
                            >
                                <h3 className="screenshot-title">{screenshots[currentIndex].title}</h3>
                                <p className="screenshot-description">{screenshots[currentIndex].description}</p>
                            </motion.div>
                        </AnimatePresence>

                        {/* Thumbnails */}
                        <div className="screenshots-thumbnails">
                            {screenshots.map((screenshot, index) => (
                                <button
                                    key={index}
                                    className={`screenshot-thumbnail ${index === currentIndex ? 'active' : ''}`}
                                    onClick={() => setCurrentIndex(index)}
                                >
                                    <img src={screenshot.src} alt={screenshot.alt} />
                                </button>
                            ))}
                        </div>

                        {/* Dots */}
                        <div className="screenshots-dots">
                            {screenshots.map((_, index) => (
                                <button
                                    key={index}
                                    className={`screenshot-dot ${index === currentIndex ? 'active' : ''}`}
                                    onClick={() => setCurrentIndex(index)}
                                />
                            ))}
                        </div>
                    </div>
                </FadeIn>
            </div>
        </section>
    )
}
