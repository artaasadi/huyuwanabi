export default function DashboardPage() {
  return (
    <div style={{ padding: "2rem" }}>
      <header style={{ marginBottom: "2rem" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 700, marginBottom: "0.5rem" }}>Timeline</h1>
        <p style={{ color: "#a1a1aa" }}>Your life, chronologically.</p>
      </header>

      {/* Quick-Capture Bar Placeholder */}
      <div 
        style={{ 
          marginBottom: "3rem", 
          padding: "1rem", 
          backgroundColor: "#111827", 
          border: "1px solid #1f2937",
          borderRadius: "8px"
        }}
      >
        <input 
          type="text" 
          placeholder="[thought] What's on your mind? (Use [life-node], [status], etc.)"
          style={{
            width: "100%",
            background: "transparent",
            border: "none",
            color: "white",
            fontSize: "1rem",
            outline: "none"
          }}
        />
      </div>

      {/* Timeline Canvas Placeholder */}
      <div 
        style={{ 
          height: "400px", 
          border: "1px dashed #374151", 
          borderRadius: "8px",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#6b7280"
        }}
      >
        <p>Horizontal Timeline Canvas Space</p>
      </div>
    </div>
  );
}
