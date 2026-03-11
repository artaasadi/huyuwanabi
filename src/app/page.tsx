
import "./globals.css"; // Ensure globals CSS is loaded

export default function LandingPage() {
  return (
    <main
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
      <div style={{ textAlign: "center", maxWidth: "600px", padding: "2rem" }}>
        <h1
          style={{
            fontSize: "3.5rem",
            fontWeight: 800,
            marginBottom: "1rem",
            background: "linear-gradient(to right, #ffffff, #a1a1aa)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Track who you&apos;re becoming.
        </h1>
        <p style={{ fontSize: "1.25rem", color: "#a1a1aa", marginBottom: "3rem" }}>
          Huyuwanabi is a timeseries-first journal, life tracker, and digital builder resume. 
          Designed for those who want to document their journey.
        </p>

        <div style={{ display: "flex", gap: "1rem", justifyContent: "center" }}>
          <button
            style={{
              padding: "0.75rem 1.5rem",
              borderRadius: "8px",
              border: "1px solid #333",
              backgroundColor: "#111827",
              color: "white",
              fontSize: "1rem",
              fontWeight: 600,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.5rem",
              transition: "background-color 0.2s",
            }}
          >
            Login with GitHub
          </button>
          <button
            style={{
              padding: "0.75rem 1.5rem",
              borderRadius: "8px",
              border: "1px solid #333",
              backgroundColor: "#111827",
              color: "white",
              fontSize: "1rem",
              fontWeight: 600,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.5rem",
              transition: "background-color 0.2s",
            }}
          >
            Login with Twitter
          </button>
        </div>
      </div>
    </main>
  );
}
