$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
.\venv\Scripts\Activate.ps1
Write-Host "Backend starting on http://localhost:8000" -ForegroundColor Green
uvicorn main:app --host 0.0.0.0 --port 8000

