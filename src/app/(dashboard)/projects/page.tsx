

export default function ProjectsPage() {
  return (
    <div style={{ padding: "2rem" }}>
      <header style={{ marginBottom: "2rem", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <h1 style={{ fontSize: "2rem", fontWeight: 700, marginBottom: "0.5rem" }}>Projects</h1>
          <p style={{ color: "#a1a1aa" }}>Manage your long-term efforts.</p>
        </div>
        <button
          style={{
            padding: "0.5rem 1rem",
            backgroundColor: "#fff",
            color: "#0B0F19",
            borderRadius: "6px",
            border: "none",
            fontWeight: 600,
            cursor: "pointer"
          }}
        >
          New Project
        </button>
      </header>

      <div 
        style={{
          padding: "2rem",
          border: "1px dashed #374151",
          borderRadius: "8px",
          textAlign: "center"
        }}
      >
        <p style={{ color: "#a1a1aa", marginBottom: "1rem" }}>You haven&apos;t added any projects yet.</p>
      </div>
    </div>
  );
}
