# Huyuwanabi — Architecture

## Overview

Huyuwanabi is built on three layers:

1. **Next.js 14 App Router** — Server-side rendering, API routes, and the React UI
2. **Supabase** — PostgreSQL database, Auth (OAuth), Row Level Security, and Edge Functions
3. **RSS Worker** — A Supabase Edge Function triggered by `pg_cron` every 15 minutes

```
┌─────────────────────────────────────────────────────────┐
│                        Browser                           │
│  ┌────────────────┐   ┌──────────────────────────────┐  │
│  │  Timeline UI   │   │     Quick-Capture Bar         │  │
│  │  (Canvas.tsx)  │   │     (CaptureBar.tsx)          │  │
│  └───────┬────────┘   └──────────────┬───────────────┘  │
└──────────┼──────────────────────────┼───────────────────┘
           │  fetch()                 │  POST /api/capture
           ▼                          ▼
┌──────────────────────────────────────────────────────────┐
│                     Next.js App Router                    │
│                                                          │
│  GET /api/timeline          POST /api/capture            │
│  GET /api/public/[username] POST /api/projects           │
│  GET /api/projects          POST /api/projects/[id]/events│
│  POST /api/rss/connect      POST /api/rss/sync           │
│                                                          │
│  src/lib/parser/  ──────────► parseCapture()             │
│  src/lib/supabase/ ─────────► Supabase server client     │
└───────────────────────────────────────┬─────────────────┘
                                        │ Supabase JS SDK
                                        ▼
┌──────────────────────────────────────────────────────────┐
│                        Supabase                           │
│                                                          │
│  PostgreSQL (RLS + Triggers)   Auth (OAuth)              │
│  ┌──────────┐ ┌─────────────┐  ┌────────────────────┐   │
│  │ profiles │ │  life_nodes │  │ GitHub / X / Google│   │
│  │ projects │ │  thoughts   │  └────────────────────┘   │
│  │   eras   │ │    tags     │                            │
│  │rss_items │ │ rss_sources │                            │
│  └──────────┘ └─────────────┘                            │
│                                                          │
│  Edge Functions                 pg_cron                  │
│  ┌──────────────────────────┐   ┌──────────────────┐    │
│  │  supabase/functions/     │◄──│ */15 * * * *     │    │
│  │    rss-sync/index.ts     │   └──────────────────┘    │
│  └──────────────────────────┘                            │
└──────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
huyuwanabi/
├── src/
│   ├── app/
│   │   ├── (public)/                        # Public-facing routes (no auth)
│   │   │   ├── [username]/
│   │   │   │   └── page.tsx                 # /username — public profile timeline
│   │   │   └── layout.tsx
│   │   │
│   │   ├── (auth)/                          # Auth flow routes
│   │   │   ├── login/
│   │   │   │   └── page.tsx                 # OAuth provider selection
│   │   │   ├── callback/
│   │   │   │   └── route.ts                 # OAuth callback handler (code exchange)
│   │   │   ├── onboarding/
│   │   │   │   └── page.tsx                 # Username claim + origin date
│   │   │   └── layout.tsx
│   │   │
│   │   ├── (dashboard)/                     # Authenticated user routes
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx                 # Main timeline canvas
│   │   │   ├── projects/
│   │   │   │   ├── page.tsx                 # Project list
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx             # Individual project view
│   │   │   ├── settings/
│   │   │   │   ├── page.tsx                 # Profile settings
│   │   │   │   └── integrations/
│   │   │   │       └── page.tsx             # RSS source management
│   │   │   └── layout.tsx
│   │   │
│   │   ├── api/
│   │   │   ├── capture/
│   │   │   │   └── route.ts                 # POST: Quick-Capture parser + router
│   │   │   ├── timeline/
│   │   │   │   └── route.ts                 # GET: Unified timeline data
│   │   │   ├── public/
│   │   │   │   └── [username]/
│   │   │   │       └── route.ts             # GET: Public profile data
│   │   │   ├── projects/
│   │   │   │   ├── route.ts                 # GET, POST
│   │   │   │   └── [id]/
│   │   │   │       ├── route.ts             # GET, PATCH, DELETE
│   │   │   │       └── events/
│   │   │   │           └── route.ts         # GET, POST
│   │   │   ├── life-nodes/
│   │   │   │   └── route.ts                 # GET, POST
│   │   │   ├── thoughts/
│   │   │   │   └── route.ts                 # GET, POST
│   │   │   ├── eras/
│   │   │   │   └── route.ts                 # GET, POST
│   │   │   └── rss/
│   │   │       ├── connect/
│   │   │       │   └── route.ts             # POST: add RSS source
│   │   │       └── sync/
│   │   │           └── route.ts             # POST: trigger manual sync
│   │   │
│   │   ├── layout.tsx                       # Root layout
│   │   ├── page.tsx                         # Landing page
│   │   └── globals.css
│   │
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── server.ts                    # createServerClient (Server Components / Route Handlers)
│   │   │   ├── browser.ts                   # createBrowserClient (Client Components)
│   │   │   └── middleware.ts                # updateSession() for session refresh
│   │   ├── parser/
│   │   │   ├── index.ts                     # parseCapture() — main parse function
│   │   │   └── types.ts                     # ParsedCapture interface
│   │   └── rss/
│   │       ├── parser.ts                    # Feed XML parsing (rss-parser)
│   │       └── ingest.ts                    # Deduplication + DB insert logic
│   │
│   ├── types/
│   │   ├── database.ts                      # Auto-generated Supabase types (supabase gen types)
│   │   └── api.ts                           # API request/response types + TimelineItem union
│   │
│   └── components/
│       ├── timeline/
│       │   ├── Canvas.tsx                   # Root horizontal scroll container
│       │   ├── TimeAxis.tsx                 # Top ruler (decade/year/month/week/day)
│       │   ├── Lane.tsx                     # A single horizontal track
│       │   ├── Node.tsx                     # Point-in-time dot (life_node, thought, project_event)
│       │   └── EraBlock.tsx                 # Interval colored block (era, project bar)
│       ├── capture/
│       │   └── CaptureBar.tsx               # Quick-Capture input bar
│       └── ui/                              # Reusable primitives (Button, Modal, Badge, etc.)
│
├── supabase/
│   ├── functions/
│   │   └── rss-sync/
│   │       └── index.ts                     # RSS ingestion Edge Function
│   └── migrations/
│       └── 20240101000000_initial_schema.sql # Initial schema (mirrors docs/SCHEMA.sql)
│
├── middleware.ts                             # Next.js middleware — session refresh on every request
├── docs/
│   ├── SCHEMA.sql
│   ├── ARCHITECTURE.md                      # (this file)
│   └── PROJECT.md
└── PRODUCT_VISION.md
```

---

## Supabase Client Setup

### Server Client — `src/lib/supabase/server.ts`

Used in Server Components, Route Handlers, and Server Actions.

```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database'

export function createClient() {
  const cookieStore = cookies()
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch { /* Ignored in Server Components (read-only) */ }
        },
      },
    }
  )
}
```

### Browser Client — `src/lib/supabase/browser.ts`

Used in Client Components. Singleton pattern prevents duplicate instances.

```typescript
import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types/database'

let client: ReturnType<typeof createBrowserClient<Database>> | null = null

export function createClient() {
  if (!client) {
    client = createBrowserClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )
  }
  return client
}
```

### Middleware — `src/middleware.ts`

Refreshes the user session on every request to prevent stale tokens.

```typescript
import { updateSession } from '@/lib/supabase/middleware'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

---

## Quick-Capture Parser

The Quick-Capture Bar sends a raw string to `POST /api/capture`. The parser converts that string into a structured `ParsedCapture` object that the route handler can use to insert into the correct table.

### Types — `src/lib/parser/types.ts`

```typescript
export type CaptureType =
  | 'thought'
  | 'status'
  | 'project_update'
  | 'life_node'
  | 'era'

export interface ParsedCapture {
  type: CaptureType
  /** The cleaned content string (hashtags stripped). */
  content: string
  /**
   * Type-specific target:
   *  - project_update → project slug
   *  - era            → era title (from [era: title] syntax)
   */
  target?: string
  /** Tag slugs extracted from inline #hashtag syntax. */
  tags: string[]
  timestamp: Date
  isBackdated: boolean
}
```

### Parser — `src/lib/parser/index.ts`

**Syntax Reference:**

| Input                                   | Result                                              |
|-----------------------------------------|-----------------------------------------------------|
| `[thought] text`                        | `type: 'thought', content: 'text'`                  |
| `[status] text`                         | `type: 'status', content: 'text'` (creates an era)  |
| `[project-update: my-app] Fixed auth`   | `type: 'project_update', target: 'my-app'`          |
| `[life-node] Got first customer #startup` | `type: 'life_node', tags: ['startup']`            |
| `[era: Living in Tokyo] Moved to Japan` | `type: 'era', target: 'Living in Tokyo'`            |
| `Just a plain thought`                  | defaults to `type: 'thought'`                       |

Inline `#hashtag` tokens are extracted from the content of any entry type and resolved to tag slugs. They are stripped from the final `content` string.

```typescript
const PATTERNS: Array<{ type: CaptureType; regex: RegExp }> = [
  { type: 'thought',        regex: /^\[thought\]\s*(.+)$/si },
  { type: 'status',         regex: /^\[status\]\s*(.+)$/si },
  { type: 'project_update', regex: /^\[project-update:\s*([^\]]+)\]\s*(.+)$/si },
  { type: 'life_node',      regex: /^\[life-node\]\s*(.+)$/si },
  { type: 'era',            regex: /^\[era:\s*([^\]]+)\]\s*(.+)$/si },
]

const HASHTAG_REGEX = /#([a-z0-9-]+)/gi

export function parseCapture(raw: string): ParsedCapture {
  const trimmed = raw.trim()

  for (const { type, regex } of PATTERNS) {
    const match = trimmed.match(regex)
    if (!match) continue

    let content: string
    let target: string | undefined

    if (type === 'project_update' || type === 'era') {
      target  = match[1].trim()
      content = match[2].trim()
    } else {
      content = match[1].trim()
    }

    const tags = extractTags(content)
    content = content.replace(HASHTAG_REGEX, '').replace(/\s{2,}/g, ' ').trim()

    return { type, content, target, tags, timestamp: new Date(), isBackdated: false }
  }

  // Default: plain text becomes a thought
  const content = trimmed.replace(HASHTAG_REGEX, '').replace(/\s{2,}/g, ' ').trim()
  return {
    type: 'thought',
    content,
    tags: extractTags(trimmed),
    timestamp: new Date(),
    isBackdated: false,
  }
}

function extractTags(text: string): string[] {
  const matches = [...text.matchAll(HASHTAG_REGEX)]
  return [...new Set(matches.map(m => m[1].toLowerCase()))]
}
```

---

## API Routes

### `POST /api/capture`

The unified entry point for the Quick-Capture Bar.

**Request body:** `{ raw: string }`

**Logic:**
1. Authenticate user (redirect to login if no session)
2. Call `parseCapture(raw)` → `ParsedCapture`
3. Resolve tag slugs to tag IDs (batch lookup in `tags` table; auto-create unknown user tags)
4. Switch on `parsed.type`:
   - `thought` → `INSERT INTO thoughts (user_id, content, source='manual', occurred_at)`
   - `status` → `INSERT INTO eras (user_id, title=content, start_date=today)` (creates an open-ended era)
   - `project_update` → look up project by `slug` for user → `INSERT INTO project_events`
   - `life_node` → `INSERT INTO life_nodes` → `INSERT INTO life_node_tags`
   - `era` → `INSERT INTO eras (title=target, description=content)` → `INSERT INTO era_tags`
5. Return `{ success: true, data: { id, type, ... } }`

**Error cases:**
- `project_update` with unknown slug → 404
- Missing `raw` field → 400
- Auth failure → 401

---

### `GET /api/timeline`

Returns all timeline data for the authenticated user, merged into a single sorted array.

**Query params:**
- `from` (ISO 8601 date, optional) — start of range
- `to` (ISO 8601 date, optional) — end of range
- `types` (comma-separated, optional) — filter: `thoughts,life_nodes,projects,eras,project_events`

**Logic:**
1. Run parallel queries for each requested type:
   - `thoughts`: `SELECT * FROM thoughts WHERE user_id = ? AND occurred_at BETWEEN from AND to`
   - `life_nodes`: same with `occurred_at`
   - `projects`: `SELECT * FROM projects WHERE user_id = ? AND start_date <= to AND (end_date IS NULL OR end_date >= from)`
   - `eras`: same pattern as projects
   - `project_events`: joined with projects
2. Annotate each item with a `_type` discriminant field
3. Sort merged array by canonical timestamp descending
4. Return `{ items: TimelineItem[], meta: { total, from, to } }`

---

### `GET /api/public/[username]`

Returns all public timeline data for a given username. No auth required.

**Logic:**
1. Look up `profiles WHERE username = ? AND is_public = true` → 404 if not found or private
2. Run the same parallel queries as `/api/timeline` but for that user's `user_id`
3. Return public profile + timeline items

---

### `POST /api/projects`

Creates a new project. Auto-generates `slug` from `title` if not provided.

**Request body:** `{ title, description?, status?, start_date?, slug? }`

---

### `PATCH /api/projects/[id]`

Updates mutable project fields (title, description, website_url, repo_url, status, end_date). Does **not** enforce the immutability trigger — the projects table is freely editable. If `status` changes, the API also creates a `project_events` row of type `status_change`.

---

### `POST /api/projects/[id]/events`

Logs a new event on a project's timeline. Subject to the 24-hour immutability trigger from the DB.

**Request body:** `{ event_type, title, description?, occurred_at?, is_backdated?, metadata? }`

---

### `POST /api/rss/connect`

Registers a new RSS source for the user.

**Request body:** `{ url: string }`

**Logic:**
1. Validate URL format
2. Attempt to fetch the feed to verify it's a valid RSS/Atom feed and extract the feed title
3. `INSERT INTO rss_sources (user_id, url, title, source_type)`
4. Trigger an immediate first sync by calling the edge function
5. Return the created source row

---

### `POST /api/rss/sync`

Triggers a manual sync of all active RSS sources for the authenticated user.

**Logic:** Calls the Supabase Edge Function `rss-sync` via the service role, scoped to the user's sources.

---

## RSS Worker

**Location:** `supabase/functions/rss-sync/index.ts`

**Trigger:** `pg_cron` job every 15 minutes (defined in `SCHEMA.sql`). Can also be triggered manually via `POST /api/rss/sync`.

### Algorithm

```
1. Query: SELECT * FROM rss_sources WHERE status = 'active'
   (Optional: filter by user_id if called with a specific user scope)

2. For each source in parallel:

   a. Try: fetch(source.url, { signal: AbortSignal.timeout(10000) })
   b. Parse XML → items[] using rss-parser library

   c. For each item in items[]:
      i.  Determine guid = item.guid || item.link || hash(item.title + item.pubDate)
      ii. Check: SELECT 1 FROM rss_items WHERE rss_source_id = source.id AND guid = ?
      iii. If NOT EXISTS:
           - INSERT INTO rss_items (rss_source_id, user_id, guid, url, title, content, published_at)
           - Determine source type: if source.url contains "twitter.com" or "x.com" → 'twitter_rss', else 'rss'
           - Determine is_backdated: published_at < now() - interval '1 hour' → true
           - INSERT INTO thoughts (user_id, content=item.title||'\n\n'||item.description, source, rss_item_id, occurred_at=published_at, url=item.link, is_backdated)

   d. On success: UPDATE rss_sources SET last_synced_at = now() WHERE id = source.id
   e. On error:   UPDATE rss_sources SET status = 'error', last_error = err.message, last_error_at = now()

3. Return { synced: N, new_items: M, errors: [...] }
```

### Deduplication Strategy

Two-layer approach:
1. **Pre-check** (step c.ii above): avoids redundant inserts and saves a DB write
2. **Database constraint** (`UNIQUE(rss_source_id, guid)` on `rss_items`): the final safety net; if two worker instances race, the second insert will fail with a unique violation, which is caught and ignored

### Error Handling

- Feed fetch errors (network timeout, 404, etc.) → set `status = 'error'` on the source row
- XML parse errors → set `status = 'error'`
- Individual item insert errors → log, continue with remaining items (don't abort entire source)
- Sources with `status = 'error'` are excluded from automatic syncs until manually re-enabled by the user

---

## Authentication Flow

Supabase Auth handles all OAuth. The flow:

1. User clicks "Sign in with GitHub/X/Google" on `/login`
2. Supabase client initiates OAuth redirect
3. Provider redirects to `/auth/callback?code=...`
4. `callback/route.ts` exchanges the code for a session via `supabase.auth.exchangeCodeForSession(code)`
5. If new user → redirect to `/onboarding` to claim username + set origin date
6. If existing user → redirect to `/dashboard`

### New User Profile Creation

The `profiles` table is populated in two ways:
- **Automatic**: A Supabase Database Webhook or Auth Hook triggers an `INSERT INTO profiles` on new user creation (handles `id` and `avatar_url` from OAuth metadata)
- **Onboarding**: The `/onboarding` page updates the profile row with `username`, `display_name`, and `origin_date`

---

## Environment Variables

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...        # Server-only, never exposed to client

# App
NEXT_PUBLIC_APP_URL=https://huyuwanabi.com
```

Required in Supabase project settings (for pg_cron → Edge Function calls):
```sql
ALTER DATABASE postgres SET "app.supabase_functions_url" = 'https://your-project.supabase.co/functions/v1';
ALTER DATABASE postgres SET "app.service_role_key" = 'eyJ...';
```

---

## Key Packages

```json
{
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "@supabase/supabase-js": "^2.0.0",
    "@supabase/ssr": "^0.5.0",
    "rss-parser": "^3.13.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "supabase": "^1.0.0"
  }
}
```
