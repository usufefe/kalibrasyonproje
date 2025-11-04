# VIDCO AI CO-PILOT - SİSTEM MİMARİSİ

## 🏗️ GENEL MİMARİ YAPISI

```
┌─────────────────────────────────────────────────────────────┐
│                      SUNUM KATMANI                          │
├─────────────────────────────────────────────────────────────┤
│  Flutter Cross-Platform (Web, Windows, Android, iOS)        │
│  • Dashboard & Analytics                                     │
│  • Organizasyon Yönetimi                                    │
│  • Cihaz Kayıt & Takip                                      │
│  • Ses Kayıt & Upload                                       │
│  • PDF Görüntüleme & İndirme                               │
└─────────────────────────────────────────────────────────────┘
                              ↕ HTTPS/REST API
┌─────────────────────────────────────────────────────────────┐
│                        API GATEWAY                          │
├─────────────────────────────────────────────────────────────┤
│  FastAPI (Python) - Port 8000                               │
│  • Authentication & Authorization (JWT)                      │
│  • Rate Limiting & Throttling                              │
│  • Request/Response Validation                             │
│  • CORS Management                                          │
│  • API Versioning (/api/v1)                                │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                     İŞ MANTIK KATMANI                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ Rapor Servisi   │  │ Organizasyon     │                 │
│  │ • PDF Generator │  │ Servisi          │                 │
│  │ • Template Mgr  │  │ • CRUD Ops       │                 │
│  │ • Version Ctrl  │  │ • Validation     │                 │
│  └─────────────────┘  └──────────────────┘                 │
│                                                             │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ Cihaz Servisi   │  │ Standart Servisi │                 │
│  │ • Device Types  │  │ • ISO 17020      │                 │
│  │ • Calibration   │  │ • ISO 17025      │                 │
│  │ • History       │  │ • ISO 17662      │                 │
│  └─────────────────┘  └──────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                      AI KATMANI                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────┐              │
│  │         OpenAI Entegrasyonu              │              │
│  ├──────────────────────────────────────────┤              │
│  │ • Whisper API (Ses → Metin)              │              │
│  │ • GPT-4o-mini (Metin Analiz & Format)    │              │
│  │ • GPT-4 Vision (Görsel Analiz)           │              │
│  └──────────────────────────────────────────┘              │
│                                                             │
│  ┌──────────────────────────────────────────┐              │
│  │         İşleme Pipeline                  │              │
│  ├──────────────────────────────────────────┤              │
│  │ 1. Audio → Text (Whisper)                │              │
│  │ 2. Text → Structured Data (GPT-4o)       │              │
│  │ 3. Data → ISO Format (Templates)         │              │
│  │ 4. Format → PDF (ReportLab/Jinja2)       │              │
│  └──────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                      VERİ KATMANI                           │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL (Docker Container: kalibrasyon_postgres)         │
│  ┌──────────────────────────────────────────┐              │
│  │ Tablolar:                                │              │
│  │ • organizasyonlar (firmalar)             │              │
│  │ • cihazlar (kalibrasyon cihazları)       │              │
│  │ • kalibrasyon_raporlari                  │              │
│  │ • calibrasyon_standardlari (ISO)         │              │
│  │ • standard_sablonlari (templates)        │              │
│  │ • kullanicilar (teknisyenler)            │              │
│  │ • ses_kayitlari (audio files meta)       │              │
│  └──────────────────────────────────────────┘              │
│                                                             │
│  ┌──────────────────────────────────────────┐              │
│  │ File Storage:                            │              │
│  │ • /backend/uploads/ (ses dosyaları)      │              │
│  │ • /backend/reports/ (PDF raporlar)       │              │
│  │ • /backend/templates/ (HTML şablonlar)   │              │
│  └──────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 VERİ AKIŞ MİMARİSİ

### 1. KALİBRASYON RAPORU OLUŞTURMA AKIŞI

```mermaid
graph TD
    A[Teknisyen Sahada] -->|Ses Kaydı| B[Flutter App]
    B -->|Upload Audio| C[FastAPI Backend]
    C -->|1. Ses Dosyası| D[File Storage]
    C -->|2. Transcribe| E[OpenAI Whisper]
    E -->|Türkçe Metin| F[GPT-4o-mini]
    F -->|Yapılandırılmış JSON| G[Rapor Generator]
    
    H[Fotoğraf Çekimi] -->|Opsiyonel| B
    B -->|Image Upload| C
    C -->|Görsel Analiz| I[GPT-4 Vision]
    I -->|Ölçüm Değerleri| G
    
    J[ISO Standartları DB] -->|Template| G
    G -->|HTML + Data| K[PDF Generator]
    K -->|ISO Formatında PDF| L[Depolama]
    L -->|Download Link| M[Müşteri]
```

### 2. ORGANİZASYON VE CİHAZ YÖNETİM AKIŞI

```mermaid
graph LR
    A[Admin Panel] -->|CRUD| B[Organizasyon API]
    B -->|SQLAlchemy ORM| C[PostgreSQL]
    
    D[Cihaz Kayıt] -->|POST| E[Cihaz API]
    E -->|Validation| F[Enum Check]
    F -->|Valid Types| C
    
    G[Standart Seçimi] -->|GET| H[Standart API]
    H -->|ISO 17662| C
    C -->|Templates| I[Rapor Şablonu]
```

## 🛠️ TEKNOLOJİ STACK DETAYLARı

### FRONTEND (Flutter)

```yaml
Çekirdek Paketler:
  - http: ^1.1.0 (API iletişimi)
  - provider: ^6.0.0 (State management)
  - flutter_sound: ^9.2.0 (Ses kayıt)
  - file_picker: ^6.0.0 (Dosya seçimi)
  - pdf_viewer: ^1.2.0 (PDF görüntüleme)
  - shared_preferences: ^2.2.0 (Local storage)
  - dio: ^5.0.0 (Advanced HTTP client)
  - flutter_bloc: ^8.1.0 (Business logic)
  
Özellikler:
  - Responsive Design (Web/Mobile/Desktop)
  - Offline Mode Support
  - Pull-to-Refresh
  - Real-time Updates (WebSocket ready)
```

### BACKEND (FastAPI)

```python
Çekirdek Kütüphaneler:
  fastapi==0.104.0
  sqlalchemy==2.0.0
  asyncpg==0.28.0
  pydantic==2.4.0
  python-multipart==0.0.6
  openai==1.0.0
  reportlab==4.0.0
  jinja2==3.1.0
  python-jose[cryptography]==3.3.0  # JWT
  passlib[bcrypt]==1.7.4  # Password hashing
  redis==5.0.0  # Cache & Queue
  celery==5.3.0  # Async tasks
  
Middleware & Extensions:
  - CORS Middleware
  - Rate Limiting
  - Request ID Tracking
  - Error Handling
  - Logging & Monitoring
```

### VERİTABANI ŞEMASI

```sql
-- Ana Tablolar
CREATE TABLE organizasyonlar (
    id SERIAL PRIMARY KEY,
    firma_adi VARCHAR(255) NOT NULL,
    vergi_no VARCHAR(20),
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(100),
    akreditasyon_no VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE cihazlar (
    id SERIAL PRIMARY KEY,
    organizasyon_id INTEGER REFERENCES organizasyonlar(id),
    cihaz_tipi CihazTipiEnum NOT NULL,
    marka VARCHAR(100),
    model VARCHAR(100),
    seri_no VARCHAR(100) UNIQUE,
    olcme_araligi VARCHAR(100),
    cozunurluk VARCHAR(50),
    son_kalibrasyon_tarihi DATE,
    sonraki_kalibrasyon_tarihi DATE
);

CREATE TABLE kalibrasyon_raporlari (
    id SERIAL PRIMARY KEY,
    rapor_no VARCHAR(50) UNIQUE,
    cihaz_id INTEGER REFERENCES cihazlar(id),
    teknisyen_id INTEGER REFERENCES kullanicilar(id),
    kalibrasyon_tarihi DATE,
    sicaklik DECIMAL(5,2),
    nem DECIMAL(5,2),
    ses_kayit_id INTEGER REFERENCES ses_kayitlari(id),
    ai_transcript TEXT,
    ai_structured_data JSONB,
    pdf_path VARCHAR(500),
    durum VARCHAR(50), -- 'taslak', 'onayda', 'tamamlandi'
    created_at TIMESTAMP DEFAULT NOW()
);

-- Enum Tipi
CREATE TYPE CihazTipiEnum AS ENUM (
    'KUMPAS',
    'MIKROMETRE', 
    'TERAZI',
    'BASINC_TRANSMITTERI',
    'SICAKLIK_OLCER',
    'MULTIMETRE',
    'PENS_AMPERMETRE',
    'IZOLASYON_MEGERI',
    'TOPRAKLAMA_MEGERI',
    'PLASMA_ARC_WELDING',
    'TIG_WELDING',
    'MIG_MAG_WELDING',
    'RESISTANCE_WELDING'
);
```

## 🔐 GÜVENLİK MİMARİSİ

### Authentication & Authorization

```
┌─────────────────┐
│   Kullanıcı     │
└────────┬────────┘
         ↓ Login
┌────────────────────────────┐
│   JWT Token Generation     │
│   • Access Token (15 min)  │
│   • Refresh Token (7 days) │
└────────┬───────────────────┘
         ↓
┌────────────────────────────┐
│     Role-Based Access      │
│   • Admin (Full Access)    │
│   • Teknisyen (Read/Write) │
│   • Viewer (Read Only)     │
└────────────────────────────┘
```

### Veri Güvenliği

- **Şifreleme**: HTTPS/TLS 1.3 (transit), AES-256 (rest)
- **API Key Management**: Environment variables
- **SQL Injection Protection**: Parameterized queries
- **File Upload Validation**: Type, size, virus scan
- **Rate Limiting**: 100 req/min per IP
- **GDPR/KVKK Uyumlu**: Veri anonimleştirme, silme hakkı

## 🚀 DEPLOYMENT MİMARİSİ

### Docker Compose Yapısı

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: kalibrasyon_postgres
    environment:
      POSTGRES_DB: kalibrasyon_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    container_name: kalibrasyon_backend
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@postgres:5432/kalibrasyon_db
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      REDIS_URL: redis://redis:6379
    ports:
      - "8000:8000"
    volumes:
      - ./backend/uploads:/app/uploads
      - ./backend/reports:/app/reports

  redis:
    image: redis:7-alpine
    container_name: kalibrasyon_redis
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    container_name: kalibrasyon_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend

volumes:
  postgres_data:
```

## 📊 PERFORMANS OPTİMİZASYONU

### Backend Optimizasyonları

1. **Async Operations**: FastAPI async endpoints
2. **Connection Pooling**: SQLAlchemy async pool (min=5, max=20)
3. **Redis Cache**: Sık kullanılan standartlar, organizasyon listesi
4. **Lazy Loading**: Büyük PDF'ler için streaming
5. **Background Tasks**: Celery ile uzun süren işlemler

### Frontend Optimizasyonları

1. **State Management**: Provider/BLoC pattern
2. **Lazy Loading**: Sayfalama ve infinite scroll
3. **Image Optimization**: WebP format, progressive loading
4. **Code Splitting**: Route-based lazy loading
5. **Offline Support**: Service Worker, local SQLite

### AI İşlem Optimizasyonları

1. **Batch Processing**: Çoklu ses dosyaları
2. **Prompt Caching**: Sık kullanılan prompt'lar
3. **Token Optimization**: Efficient prompting
4. **Fallback Strategy**: API failure durumunda local processing
5. **Queue System**: Redis + Celery for AI tasks

## 🔄 CI/CD PIPELINE

```yaml
GitHub Actions Workflow:
  - Test (Unit, Integration)
  - Build (Docker images)
  - Security Scan (Trivy, SAST)
  - Deploy to Staging
  - E2E Tests
  - Deploy to Production
  - Health Check
```

## 📈 MONITORING & LOGGING

### Monitoring Stack

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **ELK Stack**: Log aggregation (Elasticsearch, Logstash, Kibana)
- **Sentry**: Error tracking
- **Uptime Kuma**: Service availability

### Key Metrics

- API Response Time (p50, p95, p99)
- AI Processing Duration
- Database Query Performance
- Error Rates
- User Activity Analytics

## 🎯 SCALABILITY ROADMAP

### Kısa Vade (3 ay)
- [ ] WebSocket real-time updates
- [ ] Multi-tenant architecture
- [ ] Advanced caching strategy
- [ ] API rate limiting per user

### Orta Vade (6 ay)
- [ ] Microservices migration
- [ ] Kubernetes deployment
- [ ] GraphQL API option
- [ ] Multi-language support

### Uzun Vade (12 ay)
- [ ] ML model fine-tuning
- [ ] Custom AI model deployment
- [ ] Blockchain for certificate verification
- [ ] Global CDN distribution

## 🔧 DEVELOPMENT BEST PRACTICES

### Code Standards
- **Python**: PEP 8, Type hints, Black formatter
- **Dart/Flutter**: Effective Dart, flutter_lints
- **Git**: Conventional Commits, GitFlow
- **Documentation**: OpenAPI/Swagger, inline comments

### Testing Strategy
- **Unit Tests**: >80% coverage
- **Integration Tests**: API endpoints
- **E2E Tests**: Critical user flows
- **Performance Tests**: Load testing with Locust
- **Security Tests**: OWASP ZAP scanning

Bu mimari, projenizin mevcut durumu ve gelecek hedeflerini kapsayan, ölçeklenebilir ve sürdürülebilir bir yapı sunuyor. ISO standartlarına uyum, AI entegrasyonu ve kullanıcı deneyimi odaklı tasarlanmıştır.