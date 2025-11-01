# Kalibrasyon Projesi

Flutter + FastAPI + OpenAI ile AI destekli kalibrasyon rapor oluşturma sistemi.

## Özellikler
- 🎤 Ses kaydı (Web mikrofon)
- 🔊 OpenAI Whisper ile transkripsiyon
- 🤖 GPT-4o-mini ile akıllı analiz
- 📄 Otomatik PDF rapor oluşturma
- ✅ ISO 17020 uyumlu format

## Kurulum

### Backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
.\start.ps1
```

### Frontend
```bash
cd kalibrasyon_app
flutter pub get
flutter run -d chrome
```

## Kullanım
1. "Yeni Muayene Başlat" butonuna tıkla
2. Mikrofona konuş
3. "Rapor Oluştur" ile PDF indir

