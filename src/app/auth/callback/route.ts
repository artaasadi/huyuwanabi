import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

/**
 * OAuth callback handler.
 * Supabase redirects here after the user approves login on GitHub/Twitter/Google.
 * We exchange the one-time `code` for a real session, then send the user to the dashboard.
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')

  if (code) {
    const supabase = createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}/dashboard`)
    }
  }

  // Something went wrong — send back to the landing page.
  return NextResponse.redirect(`${origin}/?error=auth_failed`)
}
