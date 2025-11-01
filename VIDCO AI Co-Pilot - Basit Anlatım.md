# VIDCO AI Co-Pilot - Basit Anlatım

## 🎯 NE YAPIYORUZ?

Muayene personeli **telefona konuşuyor** → Uygulama **PDF rapor** çıkarıyor.

---

## 📱 UYGULAMA 3 SAYFA

### 1. Ana Sayfa
- Büyük buton: "Yeni Muayene Başlat"

### 2. Kayıt Sayfası
- Mikrofon butonu (bas-konuş-bırak)
- "Rapor Oluştur" butonu

### 3. Rapor Sayfası
- "PDF'i Aç" butonu
- "Paylaş" butonu

**O kadar!**

---

## 🔧 CURSOR'A NE DİYECEKSİN?

### ADIM 1: Proje Oluştur
```
Flutter projesi oluştur: vidco_ai_copilot

Paketler ekle:
- record (ses kaydı)
- http (internet)
- path_provider (dosya)
- open_file (PDF aç)
```

### ADIM 2: Ana Sayfa
```
Ana sayfa yap:
- Başlık: "VIDCO AI Co-Pilot"
- Büyük yeşil buton: "Yeni Muayene Başlat"
- Butona basınca kayıt sayfasına git
```

### ADIM 3: Kayıt Sayfası
```
Kayıt sayfası yap:
- Büyük mikrofon ikonu
- "Kayda Başla" butonu (yeşil)
- Kaydederken "Durdur" butonu (kırmızı)
- Kayıt bitince "Rapor Oluştur" butonu (mavi)
```

### ADIM 4: Backend Bağlantısı
```
Backend'e bağlan:
- Ses dosyasını http://localhost:8000/api/speech-to-text adresine gönder
- Gelen metni ekranda göster
- Metni http://localhost:8000/api/create-pdf adresine gönder
- PDF'i kaydet
```

### ADIM 5: Rapor Sayfası
```
Rapor sayfası yap:
- "Rapor Hazır!" yazısı
- "PDF'i Aç" butonu
- "Ana Sayfaya Dön" butonu
```

---

## 🚀 BACKEND (Ayrı Terminal)

```
Backend yap (FastAPI):

3 endpoint:
1. /api/speech-to-text → Ses al, metin döndür (OpenAI Whisper)
2. /api/generate-report → Metin al, JSON döndür (GPT-4)
3. /api/create-pdf → JSON al, PDF döndür (Carbone)
```

---

## 💡 CURSOR'A İLK PROMPT

```
Flutter uygulaması yap:

3 sayfa:
1. Ana sayfa - "Yeni Muayene" butonu
2. Kayıt sayfası - Mikrofon butonu, ses kaydet
3. Rapor sayfası - PDF aç butonu

Paketler: record, http, path_provider, open_file

Backend: http://localhost:8000
```

**BİTTİ!** 🎉

---

## 📝 ÖZET

**Yapacağın:**
1. Cursor'a yukarıdaki prompt'u ver
2. Backend'i ayrı çalıştır (FastAPI)
3. Flutter'ı çalıştır
4. Telefonda test et

**Süre:** 5 gün  
**Sonuç:** Çalışan uygulama
