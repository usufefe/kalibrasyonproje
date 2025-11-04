# Çalışan projeyi sonlandırma script'i

Write-Host "Projeyi sonlandırıyor..." -ForegroundColor Yellow

# Python/Uvicorn süreçlerini sonlandır
Write-Host "Python/Uvicorn süreçleri sonlandırılıyor..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*python*" -or $_.ProcessName -like "*uvicorn*"} | ForEach-Object {
    Write-Host "  Sonlandırılıyor: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Flutter süreçlerini sonlandır
Write-Host "Flutter süreçleri sonlandırılıyor..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*dart*"} | ForEach-Object {
    Write-Host "  Sonlandırılıyor: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Port 8000'i kullanan süreçleri sonlandır
Write-Host "Port 8000'i kullanan süreçler sonlandırılıyor..." -ForegroundColor Cyan
$port8000 = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($port8000) {
    foreach ($pid in $port8000) {
        Write-Host "  Sonlandırılıyor: PID $pid" -ForegroundColor Gray
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nTüm süreçler sonlandırıldı!" -ForegroundColor Green
