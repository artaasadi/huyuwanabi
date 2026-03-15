import Link from "next/link";

export default function SettingsPage() {
  return (
    <div style={{ padding: "2rem", maxWidth: "800px", margin: "0 auto" }}>
      <header style={{ marginBottom: "2rem" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 700, marginBottom: "0.5rem" }}>Settings</h1>
        <p style={{ color: "#a1a1aa" }}>Manage your profile and account.</p>
      </header>

      <div style={{ display: "flex", gap: "2rem" }}>
        <aside style={{ width: "200px" }}>
          <nav style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
            <Link href="/settings" style={{ color: "#fff", textDecoration: "none", padding: "0.5rem", borderRadius: "6px", backgroundColor: "#1f2937" }}>Profile</Link>
            <Link href="/settings/integrations" style={{ color: "#a1a1aa", textDecoration: "none", padding: "0.5rem", borderRadius: "6px" }}>Integrations</Link>
          </nav>
        </aside>

        <section style={{ flex: 1, backgroundColor: "#111827", padding: "2rem", borderRadius: "8px", border: "1px solid #1f2937" }}>
          <h2 style={{ fontSize: "1.25rem", fontWeight: 600, marginBottom: "1.5rem" }}>Profile Information</h2>
          <form style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", color: "#a1a1aa", fontSize: "0.875rem" }}>Username</label>
              <input type="text" placeholder="Update your username" style={{ width: "100%", padding: "0.75rem", borderRadius: "6px", background: "#0B0F19", border: "1px solid #374151", color: "#fff", outline: "none" }} />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", color: "#a1a1aa", fontSize: "0.875rem" }}>Bio</label>
              <textarea placeholder="Write a short bio" rows={4} style={{ width: "100%", padding: "0.75rem", borderRadius: "6px", background: "#0B0F19", border: "1px solid #374151", color: "#fff", outline: "none", resize: "none" }} />
            </div>
            <button style={{ padding: "0.75rem", backgroundColor: "#fff", color: "#0B0F19", borderRadius: "6px", border: "none", fontWeight: 600, cursor: "pointer", width: "fit-content" }}>Save Changes</button>
          </form>
        </section>
      </div>
    </div>
  );
}
