import { motion } from 'framer-motion'

export default function AnimatedBackground() {
    return (
        <div className="animated-bg" style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            zIndex: -1,
            overflow: 'hidden',
            background: '#000000'
        }}>
            {/* Primary Orb */}
            <motion.div
                style={{
                    position: 'absolute',
                    top: '-20%',
                    right: '-10%',
                    width: '60vw',
                    height: '60vw',
                    maxWidth: '800px',
                    maxHeight: '800px',
                    borderRadius: '50%',
                    background: 'radial-gradient(circle, rgba(250, 36, 60, 0.3) 0%, rgba(250, 36, 60, 0) 70%)',
                    filter: 'blur(60px)',
                }}
                animate={{
                    scale: [1, 1.1, 1],
                    x: [0, 30, 0],
                    y: [0, 20, 0],
                }}
                transition={{
                    duration: 8,
                    repeat: Infinity,
                    ease: 'easeInOut'
                }}
            />

            {/* Secondary Orb */}
            <motion.div
                style={{
                    position: 'absolute',
                    bottom: '10%',
                    left: '-10%',
                    width: '50vw',
                    height: '50vw',
                    maxWidth: '600px',
                    maxHeight: '600px',
                    borderRadius: '50%',
                    background: 'radial-gradient(circle, rgba(250, 36, 60, 0.2) 0%, rgba(250, 36, 60, 0) 70%)',
                    filter: 'blur(80px)',
                }}
                animate={{
                    scale: [1, 1.15, 1],
                    x: [0, -20, 0],
                    y: [0, -30, 0],
                }}
                transition={{
                    duration: 10,
                    repeat: Infinity,
                    ease: 'easeInOut',
                    delay: 1
                }}
            />

            {/* Accent Orb */}
            <motion.div
                style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    width: '40vw',
                    height: '40vw',
                    maxWidth: '500px',
                    maxHeight: '500px',
                    borderRadius: '50%',
                    background: 'radial-gradient(circle, rgba(255, 107, 107, 0.15) 0%, rgba(255, 107, 107, 0) 70%)',
                    filter: 'blur(100px)',
                    transform: 'translate(-50%, -50%)',
                }}
                animate={{
                    scale: [1, 1.2, 1],
                    opacity: [0.5, 1, 0.5],
                }}
                transition={{
                    duration: 12,
                    repeat: Infinity,
                    ease: 'easeInOut',
                    delay: 2
                }}
            />

            {/* Noise Overlay */}
            <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
                opacity: 0.03,
                pointerEvents: 'none',
            }} />
        </div>
    )
}
