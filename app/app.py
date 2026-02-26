from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/")
async def root():
    return HTMLResponse("""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>DevSecOps Pipeline - Aryan Patil</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box }
  body {
    font-family: Arial, sans-serif;
    background: #0f172a;
    color: #e2e8f0;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 30px;
  }
  .card {
    background: #1e293b;
    border: 1px solid #2d3f55;
    border-radius: 20px;
    padding: 55px 65px;
    text-align: center;
    max-width: 650px;
    width: 100%;
    box-shadow: 0 25px 60px rgba(0,0,0,0.4);
  }
  .icon { font-size: 3.5rem; margin-bottom: 20px; }
  h1 { color: #38bdf8; font-size: 2.2rem; font-weight: 700; margin-bottom: 8px; }
  .sub { color: #64748b; font-size: 1rem; margin-bottom: 30px; }
  .status {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    background: #0d2137;
    border: 1px solid #22c55e;
    border-radius: 30px;
    padding: 12px 28px;
    margin-bottom: 35px;
    color: #22c55e;
    font-weight: 600;
  }
  .dot {
    width: 10px; height: 10px;
    background: #22c55e;
    border-radius: 50%;
    animation: pulse 1.5s infinite;
  }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
  .tools {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 10px;
    margin-bottom: 35px;
  }
  .tool {
    background: #0f172a;
    border: 1px solid #2d3f55;
    border-radius: 8px;
    padding: 8px 18px;
    font-size: 0.85rem;
    color: #94a3b8;
  }
  .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    border-top: 1px solid #2d3f55;
    padding-top: 30px;
  }
  .box { background: #0f172a; border-radius: 10px; padding: 18px; }
  .box .label { color: #64748b; font-size: 0.72rem; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }
  .box .value { color: #22c55e; font-weight: 700; font-size: 1rem; }
  .footer { margin-top: 30px; color: #334155; font-size: 0.8rem; }
  .footer span { color: #38bdf8; }
</style>
</head>
<body>
<div class="card">
  <div class="icon">🛡️</div>
  <h1>DevSecOps Pipeline</h1>
  <p class="sub">Assignment by Aryan Patil</p>

  <div class="status">
    <div class="dot"></div>
    Pipeline Running Successfully on AWS
  </div>

  <div class="tools">
    <span class="tool">⚡ FastAPI</span>
    <span class="tool">🐳 Docker</span>
    <span class="tool">⚙️ Jenkins</span>
    <span class="tool">🔍 Trivy</span>
    <span class="tool">🏗️ Terraform</span>
    <span class="tool">☁️ AWS EC2</span>
    <span class="tool">🤖 AI Remediation</span>
  </div>

  <div class="grid">
    <div class="box">
      <div class="label">Pipeline Status</div>
      <div class="value">✅ PASSED</div>
    </div>
    <div class="box">
      <div class="label">Critical Vulnerabilities</div>
      <div class="value">0 Fixed ✅</div>
    </div>
    <div class="box">
      <div class="label">Security Scanner</div>
      <div class="value">Trivy 🔍</div>
    </div>
    <div class="box">
      <div class="label">Deployment</div>
      <div class="value">AWS EC2 ☁️</div>
    </div>
  </div>
</div>
<p class="footer">Built by <span>Aryan Patil</span> · DevSecOps Pipeline Assignment · 2026</p>
</body>
</html>""")

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "devsecops-demo"}