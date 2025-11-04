# Kalibrasyon Projesi - Başlatma Rehberi

## Hızlı Başlangıç

### Tek Komutla Başlat
```powershell
.\start_all.ps1
```
Bu komut PostgreSQL, Backend ve Frontend'i otomatik olarak başlatır.

---

## Manuel Başlatma

### 1. PostgreSQL (Docker)
```powershell
docker-compose up -d
```

### 2. Backend
```powershell
.\start_backend.ps1
```
veya manuel:
```powershell
cd backend
.\venv\Scripts\Activate.ps1
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Frontend
```powershell
.\start_frontend.ps1
```
veya manuel:
```powershell
cd kalibrasyon_app
flutter run -d windows
```

---

## Durdurma

Tüm süreçleri sonlandırmak için:
```powershell
.\kill_processes.ps1
```

---

## Erişim URL'leri

- **Backend API:** http://localhost:8000
- **API Documentation:** http://localhost:8000/docs
- **PostgreSQL:** localhost:5432

---

## Veritabanı İşlemleri

### Tabloları Oluştur
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python init_db.py
```

### Tabloları Sil (DİKKAT!)
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python init_db.py drop
```

---

## Gereksinimler

- Python 3.9+
- Flutter SDK
- Docker Desktop
- PostgreSQL (Docker ile çalışıyor)
- CMake 3.23+

---

## Sorun Giderme

### Port 8000 kullanımda hatası
```powershell
# Port 8000'i kullanan süreci bul
Get-NetTCPConnection -LocalPort 8000 | Select-Object OwningProcess

# Süreci sonlandır
Stop-Process -Id <PID> -Force
```

### Flutter CMake hatası
CMake'i güncelleyin ve PATH'e ekleyin. Ardından VS Code'u yeniden başlatın.

### Backend veritabanına bağlanamıyor
```powershell
# Docker container'ı kontrol et
docker ps

# Container'ı yeniden başlat
docker-compose restart
```
