import Link from "next/link";

export default function OnboardingPage() {
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
      <div style={{ maxWidth: "500px", width: "100%", padding: "2rem", backgroundColor: "#111827", borderRadius: "12px", border: "1px solid #1f2937" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 700, margin: "0 0 1rem 0" }}>Welcome to Huyuwanabi</h1>
        <p style={{ color: "#a1a1aa", marginBottom: "2rem" }}>Let&apos;s set up your profile.</p>

        <form style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
          <div>
            <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: 600 }}>Username</label>
            <input 
              type="text" 
              placeholder="e.g. johndoe"
              style={{
                width: "100%",
                padding: "0.75rem",
                borderRadius: "8px",
                border: "1px solid #374151",
                backgroundColor: "#0B0F19",
                color: "white",
                fontSize: "1rem",
                outline: "none"
              }}
            />
          </div>

          <div>
            <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: 600 }}>Origin Date</label>
            <input 
              type="date"
              style={{
                width: "100%",
                padding: "0.75rem",
                borderRadius: "8px",
                border: "1px solid #374151",
                backgroundColor: "#0B0F19",
                color: "white",
                fontSize: "1rem",
                outline: "none"
              }}
            />
            <p style={{ fontSize: "0.8rem", color: "#6b7280", marginTop: "0.5rem" }}>The starting point of your timeline.</p>
          </div>

          <Link href="/dashboard" passHref legacyBehavior>
            <a
              style={{
                marginTop: "1rem",
                padding: "0.875rem",
                borderRadius: "8px",
                border: "none",
                backgroundColor: "white",
                color: "black",
                fontSize: "1rem",
                fontWeight: 600,
                cursor: "pointer",
                textAlign: "center",
                textDecoration: "none"
              }}
            >
              Complete Setup
            </a>
          </Link>
        </form>
      </div>
    </div>
  );
}
