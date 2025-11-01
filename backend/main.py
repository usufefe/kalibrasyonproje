from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import openai
import os
from pathlib import Path
import json
from datetime import datetime
from dotenv import load_dotenv
import base64
from fpdf import FPDF

# production.env dosyasını yükle
env_file = Path(__file__).parent / "production.env"
if env_file.exists():
    load_dotenv(env_file)
else:
    load_dotenv()  # .env dosyasını dene

app = FastAPI(title="VIDCO AI Co-Pilot Backend")

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")

# Dosya kaydetme dizini
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


class TranscriptionRequest(BaseModel):
    text: str


class ReportData(BaseModel):
    muayene_turu: str
    tarih: str
    teknisyen: str
    cihaz_bilgileri: dict
    olcum_sonuclari: dict
    notlar: str
    gorsel_analiz: dict = None  # Yeni alan


class ImageAnalysisRequest(BaseModel):
    image_base64: str


@app.get("/")
async def root():
    return {"message": "VIDCO AI Co-Pilot Backend API", "status": "running"}


@app.post("/api/speech-to-text")
async def speech_to_text(file: UploadFile = File(...)):
    """
    Ses dosyasını metne çevirir (OpenAI Whisper kullanarak)
    """
    try:
        # Dosyayı kaydet
        file_path = UPLOAD_DIR / file.filename
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # OpenAI Whisper ile transkripsiyon
        with open(file_path, "rb") as audio_file:
            transcript = openai.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                language="tr"
            )
        
        # Dosyayı sil
        file_path.unlink()
        
        return {"text": transcript.text, "status": "success"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transkripsiyon hatası: {str(e)}")


@app.post("/api/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """
    Görsel analizi yapar (OpenAI GPT-4 Vision kullanarak)
    """
    try:
        # Dosyayı oku ve base64'e çevir
        content = await file.read()
        base64_image = base64.b64encode(content).decode('utf-8')
        
        # OpenAI Vision API ile analiz
        client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "Sen bir muayene ve kalibrasyon uzmanısın. Cihaz fotoğraflarını analiz edip detaylı raporlar oluşturursun."
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": """Bu cihazı analiz et ve şu bilgileri JSON formatında ver:
{
    "cihaz_turu": "Cihaz türü (basınç ölçer, termometre, vb.)",
    "gorsel_durum": "Cihazın görsel durumu (hasar, aşınma, temizlik)",
    "gosterge_deger": "Eğer göstergede bir değer okunuyorsa, o değer",
    "anomaliler": ["Tespit edilen sorunlar listesi"],
    "oneriler": ["Öneriler listesi"]
}

Sadece geçerli JSON döndür."""
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=500,
            temperature=0.3
        )
        
        # JSON parse et
        analysis_text = response.choices[0].message.content
        
        # JSON ayıklama (bazen markdown code block içinde geliyor)
        if "```json" in analysis_text:
            analysis_text = analysis_text.split("```json")[1].split("```")[0].strip()
        elif "```" in analysis_text:
            analysis_text = analysis_text.split("```")[1].split("```")[0].strip()
        
        analysis_json = json.loads(analysis_text)
        
        # Görseli kaydet
        image_filename = f"image_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        image_path = UPLOAD_DIR / image_filename
        with open(image_path, "wb") as f:
            f.write(content)
        
        return {
            "analysis": analysis_json,
            "image_filename": image_filename,
            "image_base64": base64_image,
            "status": "success"
        }
    
    except Exception as e:
        import traceback
        print(f"GORSEL ANALIZ HATA: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Görsel analiz hatası: {str(e)}")


@app.post("/api/generate-report")
async def generate_report(request: TranscriptionRequest):
    """
    Metinden rapor verisi oluşturur (GPT-4o kullanarak)
    """
    try:
        prompt = f"""
Aşağıdaki muayene ses kaydı metninden yapılandırılmış bir rapor oluştur.

Metin: {request.text}

JSON formatında şu bilgileri çıkar:
{{
    "muayene_turu": "Muayene türü (metinden çıkar, yoksa 'Kalibrasyon Muayenesi')",
    "tarih": "{datetime.now().strftime('%d.%m.%Y')}",
    "teknisyen": "Teknisyen adı (metinde varsa çıkar, yoksa 'Belirtilmemiş')",
    "cihaz_bilgileri": {{
        "marka": "Cihaz markası",
        "model": "Cihaz modeli",
        "seri_no": "Seri numarası"
    }},
    "olcum_sonuclari": {{
        "parametre1": "değer1",
        "parametre2": "değer2"
    }},
    "notlar": "Ek notlar ve gözlemler"
}}

Sadece geçerli JSON döndür, başka açıklama ekleme.
"""
        
        client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # Daha hızlı ve ucuz model
            messages=[
                {"role": "system", "content": "Sen bir muayene raporu analisti asistanısın. Verilen metinden yapılandırılmış JSON verisi çıkarırsın. Sadece geçerli JSON döndür."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        
        report_json = json.loads(response.choices[0].message.content)
        
        return report_json
    
    except Exception as e:
        # Hata durumunda fallback olarak demo data döndür
        return {
            "muayene_turu": "Kalibrasyon Muayenesi",
            "tarih": datetime.now().strftime("%d.%m.%Y"),
            "teknisyen": "Belirtilmemiş",
            "cihaz_bilgileri": {
                "marka": "Test Cihazı",
                "model": "Demo",
                "seri_no": "DEMO-001"
            },
            "olcum_sonuclari": {
                "Durum": "GPT hatası - demo veri"
            },
            "notlar": f"Orijinal metin: {request.text}\n\nHata: {str(e)}"
        }


@app.post("/api/create-pdf")
async def create_pdf(report: ReportData):
    """
    Rapor verisinden profesyonel PDF oluşturur (fpdf2 ile - Türkçe tam destek)
    """
    try:
        # Rapor numarası oluştur
        rapor_no = f"RPT-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        # PDF dosya adı
        filename = f"rapor_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        pdf_path = UPLOAD_DIR / filename
        
        # PDF oluştur
        pdf = FPDF()
        pdf.add_page()
        
        # Türkçe font ekle (DejaVu Sans yoksa atlayacak)
        try:
            pdf.add_font('DejaVu', '', 'C:/Windows/Fonts/DejaVuSans.ttf')
            pdf.add_font('DejaVu', 'B', 'C:/Windows/Fonts/DejaVuSans-Bold.ttf')
            pdf.set_font('DejaVu', '', 10)
            print("DejaVu Sans fontu yüklendi")
        except:
            # DejaVu yoksa Arial kullan
            pdf.add_font('Arial', '', 'C:/Windows/Fonts/arial.ttf')
            pdf.add_font('Arial', 'B', 'C:/Windows/Fonts/arialbd.ttf')
            pdf.set_font('Arial', '', 10)
            print("Arial fontu kullanılıyor")
        
        # Başlık
        pdf.set_font('DejaVu', 'B', 18) if 'DejaVu' in pdf.fonts else pdf.set_font('Arial', 'B', 18)
        pdf.set_text_color(30, 58, 138)
        pdf.cell(0, 10, 'MUAYENE RAPORU', ln=True, align='C')
        pdf.set_font('DejaVu', '', 11) if 'DejaVu' in pdf.fonts else pdf.set_font('Arial', '', 11)
        pdf.set_text_color(127, 140, 141)
        pdf.cell(0, 8, 'ISO/IEC 17020 Uyumlu Kalibrasyon Raporu', ln=True, align='C')
        pdf.ln(5)
        
        font_name = 'DejaVu' if 'DejaVu' in pdf.fonts else 'Arial'
        
        # GENEL BİLGİLER
        pdf.set_font(font_name, 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'GENEL BİLGİLER', ln=True, fill=True, border=1)
        pdf.set_font(font_name, '', 10)
        pdf.set_text_color(0, 0, 0)
        
        genel_data = [
            ['Rapor No:', rapor_no],
            ['Muayene Türü:', report.muayene_turu],
            ['Tarih:', report.tarih],
            ['Teknisyen:', report.teknisyen],
        ]
        
        for label, value in genel_data:
            pdf.set_fill_color(232, 244, 248)
            pdf.set_font(font_name, 'B', 10)
            pdf.cell(50, 8, label, border=1, fill=True)
            pdf.set_font(font_name, '', 10)
            pdf.cell(0, 8, value, border=1, ln=True)
        
        pdf.ln(5)
        
        # CİHAZ BİLGİLERİ
        pdf.set_font(font_name, 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'CİHAZ BİLGİLERİ', ln=True, fill=True, border=1)
        pdf.set_font(font_name, '', 10)
        pdf.set_text_color(0, 0, 0)
        
        cihaz_data = [
            ['Marka:', report.cihaz_bilgileri.get('marka', '-')],
            ['Model:', report.cihaz_bilgileri.get('model', '-')],
            ['Seri No:', report.cihaz_bilgileri.get('seri_no', '-')],
        ]
        
        for label, value in cihaz_data:
            pdf.set_fill_color(232, 244, 248)
            pdf.set_font(font_name, 'B', 10)
            pdf.cell(50, 8, label, border=1, fill=True)
            pdf.set_font(font_name, '', 10)
            pdf.cell(0, 8, value, border=1, ln=True)
        
        pdf.ln(5)
        
        # GÖRSEL ANALİZ
        if report.gorsel_analiz:
            pdf.set_font(font_name, 'B', 12)
            pdf.set_text_color(44, 62, 80)
            pdf.set_fill_color(255, 249, 230)
            pdf.cell(0, 10, 'GÖRSEL ANALİZ SONUÇLARI', ln=True, fill=True, border=1)
            pdf.set_font(font_name, '', 10)
            pdf.set_text_color(0, 0, 0)
            
            gorsel_data = [
                ['Cihaz Türü:', report.gorsel_analiz.get('cihaz_turu', '-')],
                ['Görsel Durum:', report.gorsel_analiz.get('gorsel_durum', '-')],
            ]
            
            if report.gorsel_analiz.get('gosterge_deger'):
                gorsel_data.append(['Gösterge Değeri:', str(report.gorsel_analiz.get('gosterge_deger'))])
            
            if report.gorsel_analiz.get('anomaliler'):
                anomaliler_str = ', '.join(report.gorsel_analiz.get('anomaliler', []))
                gorsel_data.append(['Anomaliler:', anomaliler_str])
            
            if report.gorsel_analiz.get('oneriler'):
                oneriler_str = ', '.join(report.gorsel_analiz.get('oneriler', []))
                gorsel_data.append(['Öneriler:', oneriler_str])
            
            for label, value in gorsel_data:
                pdf.set_fill_color(255, 249, 230)
                pdf.set_font(font_name, 'B', 10)
                pdf.cell(50, 8, label, border=1, fill=True)
                pdf.set_font(font_name, '', 10)
                pdf.multi_cell(0, 8, value, border=1)
            
            pdf.ln(5)
        
        # ÖLÇÜM SONUÇLARI
        pdf.set_font(font_name, 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'ÖLÇÜM SONUÇLARI', ln=True, fill=True, border=1)
        
        # Tablo başlığı
        pdf.set_fill_color(44, 62, 80)
        pdf.set_text_color(255, 255, 255)
        pdf.set_font(font_name, 'B', 10)
        pdf.cell(60, 10, 'Parametre', border=1, fill=True)
        pdf.cell(70, 10, 'Ölçülen Değer', border=1, fill=True)
        pdf.cell(60, 10, 'Durum', border=1, fill=True, ln=True)
        
        # Tablo içeriği
        pdf.set_text_color(0, 0, 0)
        pdf.set_font(font_name, '', 10)
        for parametre, deger in report.olcum_sonuclari.items():
            pdf.cell(60, 8, parametre, border=1)
            pdf.cell(70, 8, str(deger), border=1)
            pdf.cell(60, 8, 'Normal', border=1, ln=True)
        
        pdf.ln(5)
        
        # NOTLAR
        pdf.set_font(font_name, 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(255, 249, 230)
        pdf.cell(0, 10, 'NOTLAR VE GÖZLEMLER', ln=True, fill=True, border=1)
        pdf.set_font(font_name, '', 10)
        pdf.set_text_color(0, 0, 0)
        pdf.multi_cell(0, 6, report.notlar, border=1)
        
        pdf.ln(10)
        
        # İMZA ALANI
        pdf.set_font(font_name, 'B', 10)
        pdf.cell(95, 8, 'Muayene Yapan', border=0, align='C')
        pdf.cell(95, 8, 'Onaylayan', border=0, align='C', ln=True)
        pdf.ln(10)
        pdf.set_font(font_name, '', 10)
        pdf.cell(95, 8, report.teknisyen, border='T', align='C')
        pdf.cell(95, 8, '_____________________', border='T', align='C', ln=True)
        pdf.cell(95, 6, f'Tarih: {report.tarih}', border=0, align='C')
        pdf.cell(95, 6, 'İmza ve Tarih', border=0, align='C', ln=True)
        
        pdf.ln(10)
        
        # Footer
        pdf.set_font(font_name, '', 9)
        pdf.set_text_color(127, 140, 141)
        pdf.cell(0, 5, 'DIKKAT: Bu rapor izinsiz çoğaltılamaz ve değiştirilemez.', ln=True, align='C')
        pdf.cell(0, 5, 'Bu belge elektronik olarak oluşturulmuştur.', ln=True, align='C')
        pdf.cell(0, 5, f'Rapor No: {rapor_no} | Oluşturulma Tarihi: {report.tarih}', ln=True, align='C')
        
        # PDF'i kaydet
        pdf.output(str(pdf_path))
        
        return FileResponse(
            path=str(pdf_path),
            media_type='application/pdf',
            filename=filename
        )
    
    except Exception as e:
        import traceback
        print(f"PDF HATA: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"PDF oluşturma hatası: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

