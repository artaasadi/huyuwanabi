-- ============================================================
-- Huyuwanabi: Complete PostgreSQL Schema
-- Target: Supabase (PostgreSQL 15+)
-- Version: 1.0.0
-- ============================================================


-- ============================================================
-- SECTION 1: EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- trigram similarity for full-text search
CREATE EXTENSION IF NOT EXISTS "unaccent";  -- normalize accents for search
CREATE EXTENSION IF NOT EXISTS "pg_net";    -- HTTP calls from pg_cron (Supabase built-in)
CREATE EXTENSION IF NOT EXISTS "pg_cron";   -- job scheduling (Supabase built-in)


-- ============================================================
-- SECTION 2: ENUM TYPES
-- ============================================================

-- Project lifecycle states
CREATE TYPE project_status AS ENUM (
  'idea',
  'active',
  'paused',
  'shipped',
  'abandoned'
);

-- Types of events that can occur on a project's timeline
CREATE TYPE project_event_type AS ENUM (
  'launch',
  'feature',
  'pivot',
  'revenue_milestone',
  'status_change',
  'note'
);

-- How a thought entry was created
CREATE TYPE thought_source AS ENUM (
  'manual',
  'rss',
  'twitter_rss'
);

-- Health state of an RSS source connection
CREATE TYPE rss_source_status AS ENUM (
  'active',
  'paused',
  'error'
);


-- ============================================================
-- SECTION 3: SHARED UTILITY FUNCTIONS
-- ============================================================

-- Automatically updates the updated_at timestamp on every row mutation
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enforces the 24-hour immutability window on log/event tables.
-- Once an entry is older than 24 hours it cannot be modified or deleted.
-- This preserves the authentic, tamper-proof historical record.
CREATE OR REPLACE FUNCTION enforce_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF now() > OLD.created_at + INTERVAL '24 hours' THEN
      RAISE EXCEPTION
        'Immutability violation: entry "%" (id: %) is locked and cannot be deleted. Entries are permanently locked 24 hours after creation.',
        OLD.title, OLD.id;
    END IF;
    RETURN OLD;
  ELSE
    -- UPDATE
    IF now() > OLD.created_at + INTERVAL '24 hours' THEN
      RAISE EXCEPTION
        'Immutability violation: entry "%" (id: %) is locked and cannot be edited. Entries are permanently locked 24 hours after creation.',
        OLD.title, OLD.id;
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Variant for tables where there is no 'title' column (e.g., thoughts)
CREATE OR REPLACE FUNCTION enforce_immutability_no_title()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF now() > OLD.created_at + INTERVAL '24 hours' THEN
      RAISE EXCEPTION
        'Immutability violation: entry (id: %) is locked and cannot be deleted. Entries are permanently locked 24 hours after creation.',
        OLD.id;
    END IF;
    RETURN OLD;
  ELSE
    IF now() > OLD.created_at + INTERVAL '24 hours' THEN
      RAISE EXCEPTION
        'Immutability violation: entry (id: %) is locked and cannot be edited. Entries are permanently locked 24 hours after creation.',
        OLD.id;
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- SECTION 4: CORE TABLES
-- ============================================================

-- ------------------------------------------------------------
-- 4.1  profiles
--      One row per authenticated user. Public-facing identity.
-- ------------------------------------------------------------
CREATE TABLE profiles (
  id              UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        TEXT        NOT NULL UNIQUE,
  display_name    TEXT,
  bio             TEXT,
  avatar_url      TEXT,
  website         TEXT,
  -- The user's self-declared "builder origin" date — logged during onboarding.
  -- Anchors the leftmost point of their public timeline.
  origin_date     DATE,
  is_public       BOOLEAN     NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT username_length CHECK (char_length(username) BETWEEN 3 AND 30),
  CONSTRAINT username_format CHECK (username ~ '^[a-z0-9_-]+$')
);

CREATE INDEX idx_profiles_username ON profiles (username);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ------------------------------------------------------------
-- 4.2  tags
--      Shared, reusable labels across life_nodes, eras, and projects.
--      is_system = true rows are seeded by the platform and visible to all users.
--      user_id = NULL means it's a system/global tag.
-- ------------------------------------------------------------
CREATE TABLE tags (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT        NOT NULL,
  slug        TEXT        NOT NULL,
  color       TEXT,
  is_system   BOOLEAN     NOT NULL DEFAULT false,
  -- NULL for platform-seeded system tags; user's id for custom tags
  user_id     UUID        REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT tag_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
  -- A user cannot have two tags with the same slug.
  -- System tags (user_id IS NULL) are also unique by slug.
  UNIQUE NULLS NOT DISTINCT (slug, user_id)
);

CREATE INDEX idx_tags_user_id   ON tags (user_id);
CREATE INDEX idx_tags_is_system ON tags (is_system);
CREATE INDEX idx_tags_slug      ON tags (slug);


-- ------------------------------------------------------------
-- 4.3  life_nodes
--      Point-in-time events anchored to a specific moment.
--      Immutable after 24 hours.
-- ------------------------------------------------------------
CREATE TABLE life_nodes (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT        NOT NULL,
  description   TEXT,
  -- The actual moment this event occurred (not when it was logged).
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- True when the user is logging a past event rather than a live one.
  is_backdated  BOOLEAN     NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_life_nodes_user_occurred ON life_nodes (user_id, occurred_at DESC);

CREATE TRIGGER trg_life_nodes_updated_at
  BEFORE UPDATE ON life_nodes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_life_nodes_immutability
  BEFORE UPDATE OR DELETE ON life_nodes
  FOR EACH ROW EXECUTE FUNCTION enforce_immutability();


-- ------------------------------------------------------------
-- 4.4  projects
--      Long-lived entities that each get their own timeline lane.
--      The projects table holds current state (mutable).
--      All history is in project_events (immutable after 24h).
-- ------------------------------------------------------------
CREATE TABLE projects (
  id            UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID            NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT            NOT NULL,
  -- Short URL-safe identifier used in quick-capture: [project-update: slug]
  slug          TEXT            NOT NULL,
  description   TEXT,
  status        project_status  NOT NULL DEFAULT 'idea',
  start_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
  -- NULL = project is ongoing
  end_date      DATE,
  website_url   TEXT,
  repo_url      TEXT,
  is_backdated  BOOLEAN         NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ     NOT NULL DEFAULT now(),

  CONSTRAINT slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
  UNIQUE (user_id, slug),
  CONSTRAINT end_after_start CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_projects_user_start ON projects (user_id, start_date DESC);

CREATE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ------------------------------------------------------------
-- 4.5  project_events
--      The immutable timeseries log for each project.
--      Every significant change to a project is recorded here.
--      Immutable after 24 hours.
-- ------------------------------------------------------------
CREATE TABLE project_events (
  id            UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id    UUID                NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  -- Denormalized for RLS performance — avoids a join on every RLS check.
  user_id       UUID                NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_type    project_event_type  NOT NULL,
  title         TEXT                NOT NULL,
  description   TEXT,
  occurred_at   TIMESTAMPTZ         NOT NULL DEFAULT now(),
  is_backdated  BOOLEAN             NOT NULL DEFAULT false,
  -- Flexible payload for event-specific data.
  -- Examples:
  --   status_change:      { "from": "active", "to": "paused" }
  --   revenue_milestone:  { "amount": 1000, "currency": "USD", "mrr": true }
  --   feature:            { "feature_name": "Dark mode" }
  metadata      JSONB               NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ         NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ         NOT NULL DEFAULT now()
);

CREATE INDEX idx_project_events_project_occurred ON project_events (project_id, occurred_at DESC);
CREATE INDEX idx_project_events_user_occurred    ON project_events (user_id, occurred_at DESC);
CREATE INDEX idx_project_events_type             ON project_events (event_type);

CREATE TRIGGER trg_project_events_updated_at
  BEFORE UPDATE ON project_events
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_project_events_immutability
  BEFORE UPDATE OR DELETE ON project_events
  FOR EACH ROW EXECUTE FUNCTION enforce_immutability();


-- ------------------------------------------------------------
-- 4.6  thoughts
--      Point-in-time text entries. Created manually or via RSS ingestion.
--      Immutable after 24 hours.
-- ------------------------------------------------------------
CREATE TABLE thoughts (
  id            UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID            NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content       TEXT            NOT NULL,
  source        thought_source  NOT NULL DEFAULT 'manual',
  -- Set when this thought was auto-created from an RSS item.
  rss_item_id   UUID            REFERENCES rss_items(id) ON DELETE SET NULL,
  -- The canonical timestamp for this thought (when it was written/published).
  occurred_at   TIMESTAMPTZ     NOT NULL DEFAULT now(),
  is_backdated  BOOLEAN         NOT NULL DEFAULT false,
  -- Original post URL (for RSS-sourced entries).
  url           TEXT,
  created_at    TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_thoughts_user_occurred ON thoughts (user_id, occurred_at DESC);
-- GIN index enables efficient full-text similarity search on thought content.
CREATE INDEX idx_thoughts_content_gin   ON thoughts USING GIN (content gin_trgm_ops);

CREATE TRIGGER trg_thoughts_updated_at
  BEFORE UPDATE ON thoughts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_thoughts_immutability
  BEFORE UPDATE OR DELETE ON thoughts
  FOR EACH ROW EXECUTE FUNCTION enforce_immutability_no_title();


-- ------------------------------------------------------------
-- 4.7  eras
--      Lifestyle and vibe interval blocks — periods of time defined by
--      a start_date and an optional end_date. Rendered as colored
--      horizontal bars on the timeline.
--      Immutable after 24 hours.
-- ------------------------------------------------------------
CREATE TABLE eras (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT        NOT NULL,
  description   TEXT,
  start_date    DATE        NOT NULL,
  -- NULL = era is currently ongoing (e.g., "Living in Tokyo")
  end_date      DATE,
  -- Hex color for the rendered timeline block (e.g., "#7C3AED")
  color         TEXT,
  is_backdated  BOOLEAN     NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT end_after_start CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_eras_user_start ON eras (user_id, start_date DESC);
CREATE INDEX idx_eras_user_end   ON eras (user_id, end_date);

CREATE TRIGGER trg_eras_updated_at
  BEFORE UPDATE ON eras
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_eras_immutability
  BEFORE UPDATE OR DELETE ON eras
  FOR EACH ROW EXECUTE FUNCTION enforce_immutability();


-- ============================================================
-- SECTION 5: TAG JUNCTION TABLES
-- ============================================================

-- Many-to-many: a life_node can have multiple tags; a tag can belong to many life_nodes.
CREATE TABLE life_node_tags (
  life_node_id  UUID  NOT NULL REFERENCES life_nodes(id) ON DELETE CASCADE,
  tag_id        UUID  NOT NULL REFERENCES tags(id)       ON DELETE CASCADE,
  PRIMARY KEY (life_node_id, tag_id)
);

CREATE INDEX idx_life_node_tags_tag ON life_node_tags (tag_id);

-- Many-to-many: an era can have multiple tags.
CREATE TABLE era_tags (
  era_id    UUID  NOT NULL REFERENCES eras(id) ON DELETE CASCADE,
  tag_id    UUID  NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (era_id, tag_id)
);

CREATE INDEX idx_era_tags_tag ON era_tags (tag_id);

-- Many-to-many: a project can have multiple tags (for discovery and filtering).
CREATE TABLE project_tags (
  project_id  UUID  NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tag_id      UUID  NOT NULL REFERENCES tags(id)     ON DELETE CASCADE,
  PRIMARY KEY (project_id, tag_id)
);

CREATE INDEX idx_project_tags_tag ON project_tags (tag_id);


-- ============================================================
-- SECTION 6: RSS TABLES
-- ============================================================

-- ------------------------------------------------------------
-- 6.1  rss_sources
--      RSS feeds that the user has connected to their account.
--      Each source is polled every 15 minutes by the RSS worker.
-- ------------------------------------------------------------
CREATE TABLE rss_sources (
  id              UUID                NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID                NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  url             TEXT                NOT NULL,
  -- Auto-detected from the feed's <title> element on first sync.
  title           TEXT,
  -- Distinguishes between a generic RSS feed and a Twitter/X RSS feed
  -- (Twitter RSS items are tagged as thoughts with source='twitter_rss').
  source_type     thought_source      NOT NULL DEFAULT 'rss',
  status          rss_source_status   NOT NULL DEFAULT 'active',
  last_synced_at  TIMESTAMPTZ,
  last_error      TEXT,
  last_error_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ         NOT NULL DEFAULT now(),

  UNIQUE (user_id, url)
);

CREATE INDEX idx_rss_sources_user   ON rss_sources (user_id);
CREATE INDEX idx_rss_sources_status ON rss_sources (status);


-- ------------------------------------------------------------
-- 6.2  rss_items
--      Raw ingested RSS items. Acts as the deduplication ledger.
--      UNIQUE(rss_source_id, guid) prevents duplicate ingestion.
-- ------------------------------------------------------------
CREATE TABLE rss_items (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  rss_source_id   UUID        NOT NULL REFERENCES rss_sources(id) ON DELETE CASCADE,
  user_id         UUID        NOT NULL REFERENCES profiles(id)    ON DELETE CASCADE,
  -- The RSS item's unique identifier (<guid> or <id> element).
  guid            TEXT        NOT NULL,
  url             TEXT,
  title           TEXT,
  content         TEXT,
  published_at    TIMESTAMPTZ,
  ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Primary deduplication constraint: same guid from same source = same item.
  UNIQUE (rss_source_id, guid)
);

CREATE INDEX idx_rss_items_source      ON rss_items (rss_source_id);
CREATE INDEX idx_rss_items_user        ON rss_items (user_id);
CREATE INDEX idx_rss_items_published   ON rss_items (published_at DESC);


-- ============================================================
-- SECTION 7: ROW LEVEL SECURITY (RLS)
-- ============================================================
-- Philosophy:
--   - All content is public (visible to anyone, even anon).
--   - Only the owner can write (insert/update/delete) their data.
--   - Profile is_public = false hides that user's content from public reads.
--     (Enforced in the application layer via joining on profiles.is_public.)
--   - RSS tables are private — only the owner can read or write.
-- ============================================================

ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags             ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_nodes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects         ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE thoughts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE eras             ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_node_tags   ENABLE ROW LEVEL SECURITY;
ALTER TABLE era_tags         ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_tags     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rss_sources      ENABLE ROW LEVEL SECURITY;
ALTER TABLE rss_items        ENABLE ROW LEVEL SECURITY;

-- ---- profiles -----------------------------------------------

-- Anyone can read public profiles (used to render /username pages).
CREATE POLICY "profiles_select_public"
  ON profiles FOR SELECT
  USING (is_public = true OR auth.uid() = id);

-- Users can only insert/update/delete their own profile row.
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_own"
  ON profiles FOR DELETE
  USING (auth.uid() = id);

-- ---- tags ---------------------------------------------------

-- System tags are readable by everyone; user tags are readable by owner.
CREATE POLICY "tags_select"
  ON tags FOR SELECT
  USING (is_system = true OR auth.uid() = user_id);

CREATE POLICY "tags_insert_own"
  ON tags FOR INSERT
  WITH CHECK (auth.uid() = user_id AND is_system = false);

CREATE POLICY "tags_update_own"
  ON tags FOR UPDATE
  USING (auth.uid() = user_id AND is_system = false);

CREATE POLICY "tags_delete_own"
  ON tags FOR DELETE
  USING (auth.uid() = user_id AND is_system = false);

-- ---- life_nodes ---------------------------------------------

-- All life_nodes are publicly readable (profile-level gating in app layer).
CREATE POLICY "life_nodes_select"
  ON life_nodes FOR SELECT
  USING (true);

CREATE POLICY "life_nodes_insert_own"
  ON life_nodes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "life_nodes_update_own"
  ON life_nodes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "life_nodes_delete_own"
  ON life_nodes FOR DELETE
  USING (auth.uid() = user_id);

-- ---- projects -----------------------------------------------

CREATE POLICY "projects_select"
  ON projects FOR SELECT
  USING (true);

CREATE POLICY "projects_insert_own"
  ON projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "projects_update_own"
  ON projects FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "projects_delete_own"
  ON projects FOR DELETE
  USING (auth.uid() = user_id);

-- ---- project_events -----------------------------------------

CREATE POLICY "project_events_select"
  ON project_events FOR SELECT
  USING (true);

CREATE POLICY "project_events_insert_own"
  ON project_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "project_events_update_own"
  ON project_events FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "project_events_delete_own"
  ON project_events FOR DELETE
  USING (auth.uid() = user_id);

-- ---- thoughts -----------------------------------------------

CREATE POLICY "thoughts_select"
  ON thoughts FOR SELECT
  USING (true);

CREATE POLICY "thoughts_insert_own"
  ON thoughts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "thoughts_update_own"
  ON thoughts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "thoughts_delete_own"
  ON thoughts FOR DELETE
  USING (auth.uid() = user_id);

-- ---- eras ---------------------------------------------------

CREATE POLICY "eras_select"
  ON eras FOR SELECT
  USING (true);

CREATE POLICY "eras_insert_own"
  ON eras FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "eras_update_own"
  ON eras FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "eras_delete_own"
  ON eras FOR DELETE
  USING (auth.uid() = user_id);

-- ---- junction tables (inherit parent entity's access rules) --

CREATE POLICY "life_node_tags_select"   ON life_node_tags FOR SELECT USING (true);
CREATE POLICY "life_node_tags_write"    ON life_node_tags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM life_nodes WHERE id = life_node_id AND user_id = auth.uid())
);
CREATE POLICY "life_node_tags_delete"   ON life_node_tags FOR DELETE USING (
  EXISTS (SELECT 1 FROM life_nodes WHERE id = life_node_id AND user_id = auth.uid())
);

CREATE POLICY "era_tags_select"  ON era_tags FOR SELECT USING (true);
CREATE POLICY "era_tags_write"   ON era_tags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM eras WHERE id = era_id AND user_id = auth.uid())
);
CREATE POLICY "era_tags_delete"  ON era_tags FOR DELETE USING (
  EXISTS (SELECT 1 FROM eras WHERE id = era_id AND user_id = auth.uid())
);

CREATE POLICY "project_tags_select"  ON project_tags FOR SELECT USING (true);
CREATE POLICY "project_tags_write"   ON project_tags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM projects WHERE id = project_id AND user_id = auth.uid())
);
CREATE POLICY "project_tags_delete"  ON project_tags FOR DELETE USING (
  EXISTS (SELECT 1 FROM projects WHERE id = project_id AND user_id = auth.uid())
);

-- ---- rss_sources (private — owner only) ---------------------

CREATE POLICY "rss_sources_own"
  ON rss_sources FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---- rss_items (private — owner only) -----------------------

CREATE POLICY "rss_items_own"
  ON rss_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- SECTION 8: SEED DATA — SYSTEM TAGS
-- ============================================================
-- These tags are available to all users.
-- is_system = true, user_id = NULL.
-- ============================================================

INSERT INTO tags (name, slug, color, is_system, user_id) VALUES
  ('Startup',       'startup',      '#7C3AED', true, NULL),
  ('Moving',        'moving',       '#0EA5E9', true, NULL),
  ('Relationship',  'relationship', '#EC4899', true, NULL),
  ('Big Decision',  'big-decision', '#F59E0B', true, NULL),
  ('Health',        'health',       '#10B981', true, NULL),
  ('Career',        'career',       '#6366F1', true, NULL),
  ('Education',     'education',    '#3B82F6', true, NULL),
  ('Financial',     'financial',    '#84CC16', true, NULL),
  ('Personal',      'personal',     '#F97316', true, NULL),
  ('Location',      'location',     '#14B8A6', true, NULL),
  ('Tool / Stack',  'tool',         '#8B5CF6', true, NULL),
  ('Diet',          'diet',         '#22C55E', true, NULL),
  ('Milestone',     'milestone',    '#EAB308', true, NULL),
  ('Failure',       'failure',      '#EF4444', true, NULL),
  ('Side Project',  'side-project', '#A855F7', true, NULL);


-- ============================================================
-- SECTION 9: SCHEDULED RSS SYNC (pg_cron)
-- ============================================================
-- Calls the Supabase Edge Function `rss-sync` every 15 minutes.
-- Requires pg_net and pg_cron extensions.
-- IMPORTANT: Set the `app.supabase_functions_url` and
-- `app.service_role_key` config vars in your Supabase project
-- settings before running this.
-- ============================================================

SELECT cron.schedule(
  'rss-sync-every-15min',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url     := current_setting('app.supabase_functions_url') || '/rss-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body    := '{}'::jsonb
  );
  $$
);
