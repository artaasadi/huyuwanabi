# Huyuwanabi (WhoYouWannaBe) — Master Project Reference

> **For AI Agents**: This document is the canonical source of truth for the Huyuwanabi project.
> Read this before making any architectural decisions, generating code, or modifying the schema.
> Refer to `docs/SCHEMA.sql` for full SQL and `docs/ARCHITECTURE.md` for the directory structure and API contract.

---

## 1. Project Overview

**Name:** Huyuwanabi
**Tagline:** *Track who you're becoming.*
**URL pattern:** `huyuwanabi.com/username`

Huyuwanabi is a timeseries-first journal, life tracker, and digital builder resume. Designed for solo founders, indie developers, and "vibe coders" who want to document their journey — projects launched, places lived, ideas had, eras lived through — and share it publicly as an interactive, beautiful timeline. It is a deliberate departure from the noise of social media: no followers, no likes, no algorithmic feed. Just your authentic, chronological story.

---

## 2. Core Philosophy

### Everything is Timeseries

Every piece of data is anchored to time. There are two fundamental shapes of data:

| Shape | Description | Examples |
|-------|-------------|---------|
| **Point-in-Time Node** | An event that occurred at a specific moment | Life nodes, thoughts, tweets, project events |
| **Interval / Era** | A period with a start date and optional end date | Projects, lifestyle eras, location periods |

### Immutability Contract

**Entries are locked after 24 hours.** This is enforced at the PostgreSQL level via a `BEFORE UPDATE OR DELETE` trigger. Once an entry is older than 24 hours, it cannot be edited or deleted. This creates a tamper-proof, authentic historical record.

The 24-hour grace period exists to fix typos, not to rewrite history.

Users may **backdate** entries (set `occurred_at` to the past), but once logged and the 24-hour window closes, even backdated entries are permanent.

**Exception**: The `projects` table itself (metadata: title, description, links) is freely editable at any time. The immutability contract applies to the `project_events` log — the history of what happened to the project — not to the project's current metadata.

### Public by Default

All content is public. The entire value of the platform is the public profile at `/username`. There is no per-item privacy. Users who want privacy can set `profiles.is_public = false` to hide their entire profile.

---

## 3. Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | **Next.js 14** (App Router) | SSR for public profiles (SEO), RSC for dashboard |
| Language | **TypeScript 5** | Strict mode |
| Database | **Supabase / PostgreSQL 15** | RLS, triggers, pg_cron |
| Auth | **Supabase Auth** | OAuth: GitHub, Twitter/X, Google |
| Background Jobs | **Supabase Edge Functions** + `pg_cron` | RSS worker, 15-min schedule |
| Styling | **Vanilla CSS** | Maximum control for the custom timeline canvas |
| RSS Parsing | **rss-parser** | Node.js library for feed XML parsing |
| Supabase Client | **@supabase/ssr** | Correct cookie handling for Next.js App Router |

---

## 4. Architecture Overview

```
Browser
  ├── Timeline Canvas (Client Component, horizontal scroll)
  └── Quick-Capture Bar (Client Component)
         │
         ▼ POST /api/capture
Next.js App Router
  ├── API Routes (/api/*)
  ├── Server Components (dashboard, public profiles)
  └── src/lib/parser/ ──► parseCapture()
         │
         ▼ @supabase/ssr
Supabase
  ├── PostgreSQL (profiles, life_nodes, projects, project_events, thoughts, eras, tags, rss_*)
  ├── Row Level Security (owner-write, public-read)
  ├── Triggers (immutability, updated_at)
  └── Edge Functions
        └── rss-sync ◄── pg_cron (*/15 * * * *)
```

Full details: see `docs/ARCHITECTURE.md`.

---

## 5. Database Schema Summary

Full SQL: see `docs/SCHEMA.sql`.

| Table | Shape | Description |
|-------|-------|-------------|
| `profiles` | Entity | One per user. Username, bio, origin date, `is_public`. |
| `tags` | Entity | Shared labels. System tags seeded by platform; users can create custom tags. |
| `life_nodes` | Point-in-time | Life events (moved city, health milestone, big decision). Tagged via `life_node_tags`. |
| `projects` | Interval | Long-lived entities. Has `start_date`, nullable `end_date`. Freely mutable metadata. |
| `project_events` | Point-in-time | Timeseries log for a project. Immutable after 24h. Types: launch, feature, pivot, revenue_milestone, status_change, note. |
| `thoughts` | Point-in-time | Free-text stream. Source: manual, rss, or twitter_rss. Immutable after 24h. |
| `eras` | Interval | Lifestyle/vibe periods. "Lived in Berlin", "Was Vegan", "Using Cursor". Tagged via `era_tags`. Immutable after 24h. |
| `life_node_tags` | Junction | Many-to-many: life_nodes ↔ tags |
| `era_tags` | Junction | Many-to-many: eras ↔ tags |
| `project_tags` | Junction | Many-to-many: projects ↔ tags |
| `rss_sources` | Entity | Connected RSS feeds. Private (owner-only). |
| `rss_items` | Entity | Deduplication ledger for ingested feed items. Private (owner-only). |

### Key Design Points

- `thoughts.rss_item_id` links an auto-created thought back to its source `rss_items` row.
- `project_events.metadata JSONB` holds event-specific data (e.g., `{ "amount": 1000, "currency": "USD" }` for a revenue milestone).
- `profiles.origin_date DATE` is the leftmost anchor of the user's public timeline.
- The `UNIQUE NULLS NOT DISTINCT (slug, user_id)` constraint on `tags` allows system tags (`user_id IS NULL`) to share slugs across users without collision.

---

## 6. Key Design Decisions

### D1: Tags Over Enums for Categorization
**Decision:** `life_nodes` and `eras` use a shared `tags` table (many-to-many) instead of PostgreSQL ENUMs.
**Rationale:** ENUMs are rigid — adding a new category requires a schema migration. Tags are flexible: the platform seeds a default set, and users can create their own. Tags are also reusable across entity types (e.g., the `startup` tag on both a life_node and an era).

### D2: Immutability in the Database, Not the Application Layer
**Decision:** The 24-hour lock is enforced by a PostgreSQL trigger (`enforce_immutability`), not by application code.
**Rationale:** Application-layer enforcement can be bypassed by calling the DB directly (admin panel, migrations, etc.). A DB trigger is atomic and always executes. It makes the immutability a true infrastructure guarantee, not a convention.

### D3: `project_events` as the History; `projects` as the Snapshot
**Decision:** The `projects` table holds the current state (freely mutable). All historical changes go into `project_events` (immutable after 24h).
**Rationale:** You need to be able to update a project's website URL or fix a typo in the title at any time. But you should not be able to pretend a status change didn't happen. Separating snapshot from history solves this cleanly.

### D4: Public Read via RLS, Not Application Logic
**Decision:** RLS policies on all content tables use `USING (true)` for SELECT — all rows are publicly readable at the DB level.
**Rationale:** Profile-level privacy (`profiles.is_public`) is enforced by the application layer when constructing public queries (a join or WHERE clause on the profiles table). This keeps RLS simple and avoids complex cross-table RLS conditions that can have subtle bugs.

### D5: Supabase Edge Function for RSS (Not Next.js API Route)
**Decision:** The RSS ingestion worker runs as a Supabase Edge Function, scheduled by `pg_cron`.
**Rationale:** Next.js serverless functions time out at 10-60 seconds (depending on the plan) and cannot be cron-scheduled without an external service. Supabase Edge Functions run on Deno, have longer execution windows, and `pg_cron` can call them on a 15-minute schedule without any third-party dependency.

### D6: `is_backdated` Flag on All Event Tables
**Decision:** Every event table has `is_backdated BOOLEAN DEFAULT false`. It is set to `true` when `occurred_at` is in the past at the time of creation.
**Rationale:** The timeline needs to visually distinguish between "logged live at this moment" and "logged retroactively." This distinction is part of the authentic record — it lets viewers understand the confidence level of a timestamp.

### D7: Hashtag Syntax in Quick-Capture for Inline Tagging
**Decision:** The parser extracts `#tag-slug` tokens from Quick-Capture input and attaches them to the created entry.
**Rationale:** Asking the user to open a tag picker dropdown in a zero-friction capture bar defeats the purpose. Inline hashtags are the lowest-friction tagging UX — familiar from Twitter, fast to type, naturally readable.

---

## 7. Quick-Capture Syntax Reference

The Quick-Capture Bar accepts these prefix patterns. Plain text with no prefix defaults to a thought.

```
[thought] text                       → thought
[status] text                        → era (open-ended, starts today)
[project-update: project-slug] text  → project_event on that project
[life-node] text                     → life_node
[era: Era Title] text                → era with explicit title
plain text                           → thought (default)
```

**Inline tagging** (works on any type):
```
[life-node] Got first paying customer #startup #milestone
```
Tag slugs must match existing system tags or user-created tags. Unknown slugs are auto-created as user custom tags.

---

## 8. API Contract Summary

All authenticated routes require a valid Supabase session cookie.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/capture` | Required | Parse and route a Quick-Capture string |
| `GET` | `/api/timeline` | Required | Fetch own unified timeline data |
| `GET` | `/api/public/[username]` | None | Fetch public profile + timeline |
| `GET` | `/api/projects` | Required | List own projects |
| `POST` | `/api/projects` | Required | Create a project |
| `GET` | `/api/projects/[id]` | Required | Get project with events |
| `PATCH` | `/api/projects/[id]` | Required | Update project metadata |
| `DELETE` | `/api/projects/[id]` | Required | Delete project |
| `GET` | `/api/projects/[id]/events` | Required | List events for a project |
| `POST` | `/api/projects/[id]/events` | Required | Log a new project event |
| `GET` | `/api/life-nodes` | Required | List own life nodes |
| `POST` | `/api/life-nodes` | Required | Create a life node |
| `GET` | `/api/thoughts` | Required | List own thoughts |
| `POST` | `/api/thoughts` | Required | Create a thought |
| `GET` | `/api/eras` | Required | List own eras |
| `POST` | `/api/eras` | Required | Create an era |
| `POST` | `/api/rss/connect` | Required | Connect an RSS feed |
| `POST` | `/api/rss/sync` | Required | Manually trigger RSS sync |

---

## 9. Environment Variables

```bash
# Required — public (safe to expose to browser)
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Required — server-only (NEVER expose to browser)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Required — app configuration
NEXT_PUBLIC_APP_URL=https://huyuwanabi.com   # or http://localhost:3000 for dev
```

Supabase project settings (set in SQL or via the dashboard):
```sql
-- Required for pg_cron → Edge Function calls
ALTER DATABASE postgres SET "app.supabase_functions_url" = 'https://your-project-ref.supabase.co/functions/v1';
ALTER DATABASE postgres SET "app.service_role_key" = 'eyJ...';
```

---

## 10. 5-Phase Development Roadmap

### Phase 1: Foundation
**Goal:** Working auth, profiles, and schema deployed to Supabase.

**Deliverables:**
- [ ] Next.js 14 project initialized (App Router, TypeScript, Vanilla CSS)
- [ ] Supabase project created; schema from `docs/SCHEMA.sql` applied
- [ ] OAuth configured: GitHub, Twitter/X, Google
- [ ] `/auth/login`, `/auth/callback`, `/auth/onboarding` routes
- [ ] `profiles` CRUD working (claim username, set bio, origin date)
- [ ] Supabase types generated (`supabase gen types typescript`)
- [ ] Middleware for session refresh (`src/middleware.ts`)
- [ ] Basic dashboard shell at `/dashboard` (authenticated route)

**Done when:** A user can log in, claim a username, and see their empty dashboard.

---

### Phase 2: Core Data Engine
**Goal:** All data entities can be created and retrieved. Immutability is enforced.

**Deliverables:**
- [ ] All API routes implemented (`/api/capture`, `/api/timeline`, `/api/projects/*`, `/api/life-nodes`, `/api/thoughts`, `/api/eras`)
- [ ] Quick-Capture parser (`src/lib/parser/`) with full test coverage
- [ ] Inline hashtag parsing → tag resolution
- [ ] `POST /api/capture` routes correctly to all 5 entry types
- [ ] `GET /api/timeline` returns unified, sorted timeline data
- [ ] Immutability trigger validated (test: attempt to edit a >24h old entry)
- [ ] `is_backdated` flag auto-set correctly on all entries

**Done when:** A developer can create all entry types via the Quick-Capture API and retrieve a unified timeline.

---

### Phase 3: Timeline UI
**Goal:** The signature horizontal timeline canvas is functional and beautiful.

**Deliverables:**
- [ ] `Canvas.tsx` — horizontal scroll container with pinch-to-zoom
- [ ] `TimeAxis.tsx` — zoomable ruler (Decade → Year → Month → Week → Day)
- [ ] `Lane.tsx` — individual horizontal track per entity type/project
- [ ] `Node.tsx` — point-in-time dots (life_nodes, thoughts, project_events)
- [ ] `EraBlock.tsx` — colored interval blocks (eras, project bars)
- [ ] `CaptureBar.tsx` — command-palette-style input at top of dashboard
- [ ] Zoom levels: at least Decade, Year, Month views functional
- [ ] Sticky "Now" indicator on the time axis
- [ ] Click on any node/block opens a detail panel/modal
- [ ] Dark mode default (`#0B0F19` background, glowing nodes)

**Done when:** A user can see their entire life timeline in the horizontal canvas and navigate it by zooming.

---

### Phase 4: RSS & Integrations
**Goal:** Users can connect RSS feeds and their historical tweets/posts auto-populate the thoughts lane.

**Deliverables:**
- [ ] `supabase/functions/rss-sync/index.ts` Edge Function deployed
- [ ] `pg_cron` job scheduled (15-minute sync)
- [ ] `POST /api/rss/connect` — validates feed URL, fetches feed title, triggers first sync
- [ ] `POST /api/rss/sync` — manual sync trigger
- [ ] Settings → Integrations page (`/settings/integrations`) with list of connected sources
- [ ] Source status indicators (active / error) in the UI
- [ ] RSS-sourced thoughts rendered differently in the timeline (source badge)
- [ ] Twitter/X RSS feed support with `source = 'twitter_rss'` tagging

**Done when:** A user can paste their Twitter RSS URL, and their tweet history populates the thoughts lane within a few seconds.

---

### Phase 5: Public Profiles & Polish
**Goal:** The shareable `/username` URL is a beautiful, SEO-optimized public page. Product is launch-ready.

**Deliverables:**
- [ ] `GET /api/public/[username]` endpoint returning full public timeline
- [ ] `/[username]/page.tsx` — Server-rendered public profile with full timeline
- [ ] SEO: `generateMetadata()` with OG image, title, description per profile
- [ ] OG image generation (dynamic, shows the user's timeline or avatar + stats)
- [ ] Public profile has same horizontal timeline canvas (read-only, no capture bar)
- [ ] "Share profile" button with copy-to-clipboard URL
- [ ] Landing page (`/`) — interactive demo timeline with fake data
- [ ] Performance: public profiles load in <1s (ISR or SSG with revalidation)
- [ ] Accessibility pass on the timeline canvas
- [ ] Error states: 404 for unknown usernames, private profile message

**Done when:** Any user can share `huyuwanabi.com/their-username` and it renders a production-quality public timeline.

---

## 11. Testing Strategy

### Schema & Triggers
1. Run `docs/SCHEMA.sql` against a fresh Supabase local dev instance (`supabase start`)
2. **Immutability**: Insert a row → update immediately (should succeed) → manually backdate `created_at` to 25 hours ago → attempt update (should raise `Immutability violation` exception)
3. **RLS — own data**: Authenticated as User A, attempt to insert/update/delete User B's rows → should be rejected
4. **RLS — public read**: As `anon` role, SELECT from `life_nodes` → should return all public users' rows
5. **RLS — RSS tables private**: As `anon` role, SELECT from `rss_sources` → should return 0 rows

### Quick-Capture Parser
Unit test the `parseCapture()` function with:
- All 5 prefix patterns
- Plain text fallback
- Inline hashtag extraction (`#startup #health`)
- Edge cases: empty string, only hashtags, malformed prefix, multi-line content

### API Routes (Integration)
Use `supertest` or the Next.js test utilities:
- `POST /api/capture` with each entry type → verify correct table insert
- `GET /api/timeline?from=...&to=...` → verify all types returned and sorted
- Unauthenticated request to any auth-required route → 401
- `POST /api/projects/[id]/events` on another user's project → 404 or 403

### RSS Worker
1. Deploy Edge Function locally (`supabase functions serve rss-sync`)
2. Insert an `rss_sources` row with a real RSS URL
3. Call the function → verify `rss_items` and `thoughts` rows created
4. Call again → verify no duplicate rows (deduplication working)
5. Insert a source with an invalid URL → verify `status = 'error'` and `last_error` set

### End-to-End (manual)
1. Sign in via GitHub OAuth
2. Complete onboarding (claim username, set origin date)
3. Type `[life-node] Started Huyuwanabi #startup` in the Quick-Capture bar → see node appear on timeline
4. Type `[project-update: huyuwanabi] Shipped the timeline canvas` → verify project event logged
5. Connect a public RSS feed → wait for sync or trigger manually → verify thoughts populated
6. Navigate to `huyuwanabi.com/your-username` → verify public profile renders correctly
