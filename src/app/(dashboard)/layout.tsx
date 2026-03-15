import Link from 'next/link';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div
      style={{
        backgroundColor: "#0B0F19",
        color: "#ffffff",
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      <header
        style={{
          borderBottom: "1px solid #1f2937",
          padding: "1rem 2rem",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div style={{ fontWeight: 700, fontSize: "1.2rem" }}>Huyuwanabi</div>
        <nav>
          <ul style={{ display: "flex", gap: "1.5rem", listStyle: "none", margin: 0, padding: 0 }}>
            <li>
              <Link href="/dashboard" style={{ color: "#fff", textDecoration: "none" }}>Timeline</Link>
            </li>
            <li>
              <Link href="/projects" style={{ color: "#fff", textDecoration: "none" }}>Projects</Link>
            </li>
            <li>
              <Link href="/settings" style={{ color: "#fff", textDecoration: "none" }}>Settings</Link>
            </li>
          </ul>
        </nav>
      </header>

      <main style={{ flex: 1, position: "relative" }}>
        {children}
      </main>
    </div>
  );
}
