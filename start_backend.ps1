# Backend başlatma script'i
# Kullanım: .\start_backend.ps1

Write-Host "Backend başlatılıyor..." -ForegroundColor Green

# Backend dizinine git
Set-Location -Path "$PSScriptRoot\backend"

# Virtual environment'ı aktif et
Write-Host "Virtual environment aktif ediliyor..." -ForegroundColor Cyan
.\venv\Scripts\Activate.ps1

# Uvicorn ile backend'i başlat
Write-Host "Uvicorn başlatılıyor (http://localhost:8000)..." -ForegroundColor Cyan
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
