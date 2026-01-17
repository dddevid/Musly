import Navbar from './components/Navbar'
import Hero from './components/Hero'
import Features from './components/Features'
import Screenshots from './components/Screenshots'
import DownloadSection from './components/Download'
import Community from './components/Community'
import Footer from './components/Footer'
import AnimatedBackground from './components/effects/AnimatedBackground'
import './App.css'

function App() {
  return (
    <div className="app">
      <AnimatedBackground />
      <Navbar />
      <main>
        <Hero />
        <Features />
        <Screenshots />
        <DownloadSection />
        <Community />
      </main>
      <Footer />
    </div>
  )
}

export default App
