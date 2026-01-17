import { useState, useRef } from 'react'
import { motion } from 'framer-motion'

export default function SpotlightCard({
    children,
    className = '',
    spotlightColor = 'rgba(250, 36, 60, 0.15)',
    ...props
}) {
    const [position, setPosition] = useState({ x: 0, y: 0 })
    const [isHovered, setIsHovered] = useState(false)
    const cardRef = useRef(null)

    const handleMouseMove = (e) => {
        if (!cardRef.current) return
        const rect = cardRef.current.getBoundingClientRect()
        setPosition({
            x: e.clientX - rect.left,
            y: e.clientY - rect.top
        })
    }

    return (
        <motion.div
            ref={cardRef}
            className={`spotlight-card ${className}`}
            onMouseMove={handleMouseMove}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            style={{
                position: 'relative',
                overflow: 'hidden',
                background: 'rgba(255, 255, 255, 0.03)',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                borderRadius: '1rem',
            }}
            whileHover={{
                borderColor: 'rgba(255, 255, 255, 0.2)',
                y: -4
            }}
            transition={{ duration: 0.3 }}
            {...props}
        >
            {/* Spotlight Effect */}
            <motion.div
                style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    pointerEvents: 'none',
                    background: `radial-gradient(400px circle at ${position.x}px ${position.y}px, ${spotlightColor}, transparent 40%)`,
                }}
                animate={{ opacity: isHovered ? 1 : 0 }}
                transition={{ duration: 0.3 }}
            />

            {/* Content */}
            <div style={{ position: 'relative', zIndex: 1 }}>
                {children}
            </div>
        </motion.div>
    )
}
