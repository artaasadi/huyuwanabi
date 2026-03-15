import Link from "next/link";

export default function LoginPage() {
  return (
    <div
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
      <div style={{ textAlign: "center", maxWidth: "400px", width: "100%", padding: "2rem", backgroundColor: "#111827", borderRadius: "12px", border: "1px solid #1f2937" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 700, margin: "0 0 1.5rem 0" }}>Sign In</h1>
        <p style={{ color: "#a1a1aa", marginBottom: "2rem" }}>Choose a provider to continue to Huyuwanabi.</p>
        
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          <Link href="/dashboard" passHref legacyBehavior>
            <a
              style={{
                width: "100%",
                padding: "0.875rem",
                borderRadius: "8px",
                border: "1px solid #374151",
                backgroundColor: "#1f2937",
                color: "white",
                fontSize: "1rem",
                fontWeight: 600,
                cursor: "pointer",
                textDecoration: "none",
                display: "block",
              }}
            >
              Simulate GitHub Login
            </a>
          </Link>
          <Link href="/dashboard" passHref legacyBehavior>
            <a
              style={{
                width: "100%",
                padding: "0.875rem",
                borderRadius: "8px",
                border: "1px solid #374151",
                backgroundColor: "#1f2937",
                color: "white",
                fontSize: "1rem",
                fontWeight: 600,
                cursor: "pointer",
                textDecoration: "none",
                display: "block",
              }}
            >
              Simulate Twitter Login
            </a>
          </Link>
        </div>

        <div style={{ marginTop: "2rem" }}>
          <Link href="/" passHref legacyBehavior>
            <a style={{ color: "#a1a1aa", fontSize: "0.875rem", textDecoration: "none" }}>&larr; Back to Home</a>
          </Link>
        </div>
      </div>
    </div>
  );
}
