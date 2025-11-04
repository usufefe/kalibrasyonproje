# Tüm projeyi başlatma script'i
# Kullanım: .\start_all.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Kalibrasyon Projesi Başlatılıyor" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Docker'da PostgreSQL başlat
Write-Host "[1/3] PostgreSQL (Docker) başlatılıyor..." -ForegroundColor Green
docker-compose up -d
Write-Host "✓ PostgreSQL başlatıldı" -ForegroundColor Green
Write-Host ""

# 2. Backend başlat (yeni terminal)
Write-Host "[2/3] Backend başlatılıyor (yeni terminal açılacak)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-File", "$PSScriptRoot\start_backend.ps1"
Write-Host "✓ Backend terminal açıldı" -ForegroundColor Green
Write-Host ""

# Backend'in başlaması için bekle
Write-Host "Backend'in başlaması bekleniyor (5 saniye)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 3. Frontend başlat (yeni terminal)
Write-Host "[3/3] Frontend başlatılıyor (yeni terminal açılacak)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-File", "$PSScriptRoot\start_frontend.ps1"
Write-Host "✓ Frontend terminal açıldı" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Proje Başlatıldı!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend: http://localhost:8000" -ForegroundColor Yellow
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "Projeyi durdurmak için: .\kill_processes.ps1" -ForegroundColor Cyan
