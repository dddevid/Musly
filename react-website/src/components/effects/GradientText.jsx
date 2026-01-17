import { motion } from 'framer-motion'

export default function GradientText({
    children,
    className = '',
    animate = true,
    ...props
}) {
    const gradientStyle = {
        background: 'linear-gradient(135deg, #fa243c 0%, #ff6b6b 50%, #fa243c 100%)',
        backgroundSize: animate ? '200% 200%' : '100% 100%',
        WebkitBackgroundClip: 'text',
        WebkitTextFillColor: 'transparent',
        backgroundClip: 'text',
    }

    if (animate) {
        return (
            <motion.span
                className={className}
                style={gradientStyle}
                animate={{
                    backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
                }}
                transition={{
                    duration: 5,
                    repeat: Infinity,
                    ease: 'linear'
                }}
                {...props}
            >
                {children}
            </motion.span>
        )
    }

    return (
        <span className={className} style={gradientStyle} {...props}>
            {children}
        </span>
    )
}
