# Frontend başlatma script'i
# Kullanım: .\start_frontend.ps1

Write-Host "Flutter uygulaması başlatılıyor..." -ForegroundColor Green

# Frontend dizinine git
Set-Location -Path "$PSScriptRoot\kalibrasyon_app"

# Flutter'ı Windows için çalıştır
Write-Host "Flutter Windows uygulaması başlatılıyor..." -ForegroundColor Cyan
flutter run -d windows
