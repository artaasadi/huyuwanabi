# PRODUCT_VISION.md: Huyuwanabi (WhoYouWannaBe)

## The Core Concept
A beautifully designed journal, timeline platform, and digital resume where builders (solo founders, indie developers, and "vibe coders") can track their journey to success, document their lifestyle, and build in public away from the noise of standard social media. 

## The Core Philosophy: The Timeseries Architecture
**Everything is timeseries.** The overarching focus of Huyuwanabi is to track everything through time. Every action, project status, thought, and life event is tied to an exact date and time. 

**Authority through Immutability**: To maintain the integrity of a true "journey log," entries are frozen and **cannot be edited after 24 hours**. This provides enough grace period to fix typos, but enforces a permanent, honest record of the builder's path. Users can log past entries (backdating), but once logged and the 24-hour window passes, it's permanently locked.

---

## 1. MVP Scope
To make the V1 a usable and impressive timeseries engine:

### Must-Have Features (V1)
*   **Authentication**: Simplified login via **GitHub, Twitter (X), and Google**.
*   **Generalized Life Nodes**:
    *   Chronological life events that occur at a specific point in time.
    *   Categories include: `Startups`, `Moving/Location`, `Relationships`, `Big Decisions`, `Health`, etc.
*   **Deep Projects Tracking**:
    *   Projects are deeply tracked, longitudinal entities.
    *   Every project has its own timeseries data: creation date, feature additions, revenue bumps, pivots, and status changes. Users can track changes and new things added over the entire lifetime of the project.
*   **Thoughts Stream & Integration Engine**:
    *   A dedicated layer for ideas, realizations, and quick point-in-time updates.
    *   Users can write manual thoughts directly into the system.
    *   **Integrations**: Users can plug in RSS feeds (like their X/Twitter RSS, personal blog RSS, etc.) which act as automated sources feeding directly into the Thoughts stream linearly.
*   **Public Profile View**: A shareable public URL (`/username`) serving as their interactive timeline and digital builder resume.

---

## 2. Visual Layout & UX Architecture
The design represents a massive departure from standard vertical social media feeds. It looks and feels like a beautiful, premium analytics dashboard or a video editor timeline.

### Aesthetics
*   **Theme**: Dark mode default (`#0B0F19` deep backgrounds).
*   **Data Visualization Elements**: Use smooth splines, glowing nodes, and clean geometric shapes to represent timespans.
*   **Typography**: Clean, tech-forward sans-serifs (`Inter`, `Geist`, or `Outfit`).

### Anatomy of the Interface
*   **The Quick-Capture Bar (Zero Friction Logging)**:
    *   The very top of the dashboard features a unified, ultra-simple input bar (similar to a command palette or Twitter's composer, but smarter).
    *   By default, anything typed here is stamped with *Now*.
    *   Natural Language Processing (NLP) or simple syntax can parse the entry: `[thought] Just had a breakthrough`, `[status] Bootstrapping`, `[project-update: huyuwanabi] Fixed the auth bug`. 
    *   The goal: Entering current states, thoughts, or vibe changes should take under 3 seconds with zero date/time configuration needed from the very first page.
*   **The Main View (The Timeline Explorer)**:
    *   Below the Quick-Capture bar, the primary interface is the **Horizontal Canvas/Chart**.
    *   It features horizontally scrolling lanes/tracks, with a sticky "Now" indicator.
    *   Users can use scroll or pinch to **Zoom in/out** (viewing by Decade -> Year -> Month -> Week -> Day).
*   **The "Lanes" (Parallel Tracks)**:
    *   The timeline is divided into distinct tracks, with the ability to zoom in and click on any point or segment to see its exact state and list of changes.
    *   **Life Nodes & Thoughts (Point-in-Time Events)**: Events, ideas, or decisions that occurred at a specific moment. Whenever there's a thought or event, it is plotted as a distinct node on its respective lane.
    *   **Projects (Individual Lanes)**: **Each project gets its own dedicated horizontal line.** A project is tracked as a continuous bar from its inception; key updates, feature additions, or status changes appear as interactive dots on that specific project's line.
    *   **Lifestyle, Vibe & "Eras" (State Intervals)**: A generalized system for defining and visualizing periods of time. A user can add a "Statement" with a start date and an optional end date to represent an era. For example: "Lived in Berlin", "Was Vegan", "Bootstrapping", "Using Cursor". These appear as continuous colored blocks across the timeline. Clicking anywhere on the block shows the details of that state.

---

## 3. User Flow & Journey

### Step-by-Step Flow
1.  **Landing Page**: Interactive hero section showing a massive, beautiful horizontal life chart that the user can scrub across.
2.  **Authentication**: OAuth (GitHub/Twitter/Google).
3.  **Onboarding (The Foundation)**: Claim handle, provide short bio, and log their fundamental "Origin Date" node.
4.  **The Canvas (Dashboard)**: The user is dropped into their dashboard. The Quick-Capture bar is front and center; the horizontal timeline sits below it at the "Now" mark.
5.  **Adding Data (Two Distinct Modes)**:
    *   **Realtime (The Quick-Capture Bar)**: User types a thought, project update, or state change into the top bar. Hits enter. It instantly plots at the "Now" mark on the timeline. No friction.
    *   **Historical / Complex (The Timeline Editor)**: User clicks a specific area on the timeline or hits an "Add Historical Event" button to open a detailed modal, allowing them to precisely set start/end dates for past eras or backdate missed life nodes.
6.  **Connecting Sources**:
    *   Navigate to Settings -> Integrations.
    *   Paste X/Twitter RSS or blog RSS. System ingests historical data and plots historical "Thoughts" onto the timeline instantly.

## 4. Proposed Tech Stack
*   **Frontend**: Next.js (React) for built-in performant routing, SEO capabilities for public profiles, and robust API handling.
*   **Styling**: Vanilla CSS for maximum flexibility and highly tailored visual aesthetics essential for the custom timeline component.
*   **Backend / Database**: Supabase (PostgreSQL) given its excellent handling of relational and timeseries data, built-in Auth, and real-time capabilities.
