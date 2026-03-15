import Link from "next/link";

export default function IntegrationsPage() {
  return (
    <div style={{ padding: "2rem", maxWidth: "800px", margin: "0 auto" }}>
      <header style={{ marginBottom: "2rem" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 700, marginBottom: "0.5rem" }}>Settings</h1>
        <p style={{ color: "#a1a1aa" }}>Manage your profile and account.</p>
      </header>

      <div style={{ display: "flex", gap: "2rem" }}>
        <aside style={{ width: "200px" }}>
          <nav style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
            <Link href="/settings" style={{ color: "#a1a1aa", textDecoration: "none", padding: "0.5rem", borderRadius: "6px" }}>Profile</Link>
            <Link href="/settings/integrations" style={{ color: "#fff", textDecoration: "none", padding: "0.5rem", borderRadius: "6px", backgroundColor: "#1f2937" }}>Integrations</Link>
          </nav>
        </aside>

        <section style={{ flex: 1, backgroundColor: "#111827", padding: "2rem", borderRadius: "8px", border: "1px solid #1f2937" }}>
          <h2 style={{ fontSize: "1.25rem", fontWeight: 600, marginBottom: "1.5rem" }}>RSS Sources</h2>
          <p style={{ color: "#a1a1aa", marginBottom: "1rem", fontSize: "0.875rem" }}>Connect RSS feeds or your Twitter/X RSS to automatically populate your thoughts timeline.</p>
          
          <div style={{ display: "flex", gap: "0.5rem", marginBottom: "2rem" }}>
            <input type="url" placeholder="https://example.com/feed.xml" style={{ flex: 1, padding: "0.75rem", borderRadius: "6px", background: "#0B0F19", border: "1px solid #374151", color: "#fff", outline: "none" }} />
            <button style={{ padding: "0.75rem 1.5rem", backgroundColor: "#fff", color: "#0B0F19", borderRadius: "6px", border: "none", fontWeight: 600, cursor: "pointer" }}>Connect</button>
          </div>

          <div style={{ borderTop: "1px solid #374151", paddingTop: "1.5rem" }}>
            <p style={{ color: "#6b7280", fontSize: "0.875rem", textAlign: "center" }}>No integrations connected yet.</p>
          </div>
        </section>
      </div>
    </div>
  );
}
