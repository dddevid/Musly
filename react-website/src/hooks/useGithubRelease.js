import { useState, useEffect } from 'react'

const CACHE_KEY = 'musly_github_release_cache'
const CACHE_TTL_MS = 10 * 60 * 1000 // 10 minutes

/**
 * Fetches the latest Musly release from the GitHub public API (no auth required).
 * Results are cached in sessionStorage for 10 minutes to stay within the 60 req/hr limit.
 *
 * Returns: { version, date, url, loading, error }
 *   version  – tag name, e.g. "v1.0.7"
 *   date     – formatted publish date, e.g. "February 20, 2026"
 *   url      – HTML URL of the release page
 *   loading  – true while fetch is in progress
 *   error    – error message string or null
 */
export function useGithubRelease() {
    const [state, setState] = useState({ version: null, date: null, url: null, loading: true, error: null })

    useEffect(() => {
        // Check sessionStorage cache first
        try {
            const cached = sessionStorage.getItem(CACHE_KEY)
            if (cached) {
                const { data, timestamp } = JSON.parse(cached)
                if (Date.now() - timestamp < CACHE_TTL_MS) {
                    setState({ ...data, loading: false, error: null })
                    return
                }
            }
        } catch (_) { /* ignore parse errors */ }

        let cancelled = false

        fetch('https://api.github.com/repos/dddevid/Musly/releases/latest', {
            headers: { Accept: 'application/vnd.github+json' },
        })
            .then(res => {
                if (!res.ok) throw new Error(`GitHub API error ${res.status}`)
                return res.json()
            })
            .then(json => {
                if (cancelled) return
                const version = json.tag_name ?? 'latest'
                const date = json.published_at
                    ? new Date(json.published_at).toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                      })
                    : null
                const url = json.html_url ?? 'https://github.com/dddevid/Musly/releases/latest'
                const data = { version, date, url }

                // Cache result
                try {
                    sessionStorage.setItem(CACHE_KEY, JSON.stringify({ data, timestamp: Date.now() }))
                } catch (_) {}

                setState({ ...data, loading: false, error: null })
            })
            .catch(err => {
                if (cancelled) return
                setState(prev => ({ ...prev, loading: false, error: err.message }))
            })

        return () => { cancelled = true }
    }, [])

    return state
}
