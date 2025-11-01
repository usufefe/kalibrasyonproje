$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
.\venv\Scripts\Activate.ps1
Write-Host "Backend starting on http://localhost:8000" -ForegroundColor Green
python main.py

