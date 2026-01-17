import { motion } from 'framer-motion'

export default function FadeIn({
    children,
    delay = 0,
    duration = 0.6,
    direction = 'up',
    className = '',
    ...props
}) {
    const directions = {
        up: { y: 40, x: 0 },
        down: { y: -40, x: 0 },
        left: { x: 40, y: 0 },
        right: { x: -40, y: 0 },
        none: { x: 0, y: 0 }
    }

    const initial = {
        opacity: 0,
        ...directions[direction]
    }

    return (
        <motion.div
            initial={initial}
            whileInView={{ opacity: 1, x: 0, y: 0 }}
            viewport={{ once: true, margin: '-50px' }}
            transition={{
                duration,
                delay,
                ease: [0.25, 0.1, 0.25, 1]
            }}
            className={className}
            {...props}
        >
            {children}
        </motion.div>
    )
}
