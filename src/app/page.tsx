'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/browser'
import "./globals.css";

function OAuthButton({ provider, label }: { provider: 'github' | 'twitter', label: string }) {
  async function handleLogin() {
    const supabase = createClient()
    await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    })
  }

  return (
    <button onClick={handleLogin} style={btnStyle}>
      {label}
    </button>
  )
}

function EmailLogin() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    const supabase = createClient()
    await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    })
    setSent(true)
    setLoading(false)
  }

  if (sent) {
    return (
      <p style={{ color: '#a1a1aa', marginTop: '1rem' }}>
        Magic link sent! Check{' '}
        <a href="http://127.0.0.1:54324" target="_blank" rel="noreferrer" style={{ color: '#7c3aed' }}>
          Mailpit
        </a>
        {' '}to click it (local dev inbox).
      </p>
    )
  }

  return (
    <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
      <input
        type="email"
        placeholder="your@email.com"
        value={email}
        onChange={e => setEmail(e.target.value)}
        required
        style={{
          padding: '0.75rem 1rem',
          borderRadius: '8px',
          border: '1px solid #333',
          backgroundColor: '#111827',
          color: 'white',
          fontSize: '1rem',
          flex: 1,
          outline: 'none',
        }}
      />
      <button type="submit" disabled={loading} style={{ ...btnStyle, opacity: loading ? 0.6 : 1 }}>
        {loading ? 'Sending…' : 'Send magic link'}
      </button>
    </form>
  )
}

const btnStyle: React.CSSProperties = {
  padding: '0.75rem 1.5rem',
  borderRadius: '8px',
  border: '1px solid #333',
  backgroundColor: '#111827',
  color: 'white',
  fontSize: '1rem',
  fontWeight: 600,
  cursor: 'pointer',
  display: 'flex',
  alignItems: 'center',
  gap: '0.5rem',
  transition: 'background-color 0.2s',
}

export default function LandingPage() {
  return (
    <main
      style={{
        backgroundColor: "#0B0F19",
        color: "#ffffff",
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      <div style={{ textAlign: "center", maxWidth: "600px", padding: "2rem" }}>
        <h1
          style={{
            fontSize: "3.5rem",
            fontWeight: 800,
            marginBottom: "1rem",
            background: "linear-gradient(to right, #ffffff, #a1a1aa)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Track who you&apos;re becoming.
        </h1>
        <p style={{ fontSize: "1.25rem", color: "#a1a1aa", marginBottom: "3rem" }}>
          Huyuwanabi is a timeseries-first journal, life tracker, and digital builder resume.
          Designed for those who want to document their journey.
        </p>

        <div style={{ display: "flex", gap: "1rem", justifyContent: "center" }}>
          <OAuthButton provider="github" label="Login with GitHub" />
          <OAuthButton provider="twitter" label="Login with Twitter" />
        </div>

        <div style={{ margin: '1.5rem 0', color: '#4b5563', fontSize: '0.875rem' }}>
          — or —
        </div>

        <EmailLogin />
      </div>
    </main>
  );
}
