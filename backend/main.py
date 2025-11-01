from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import openai
import os
from pathlib import Path
import json
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from datetime import datetime
from dotenv import load_dotenv
from pathlib import Path

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
    Rapor verisinden PDF oluşturur
    """
    try:
        # PDF dosya adı
        filename = f"rapor_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        pdf_path = UPLOAD_DIR / filename
        
        # PDF oluştur
        doc = SimpleDocTemplate(str(pdf_path), pagesize=A4)
        story = []
        styles = getSampleStyleSheet()
        
        # Başlık
        title = Paragraph("<b>MUAYENE RAPORU</b>", styles['Title'])
        story.append(title)
        story.append(Spacer(1, 1*cm))
        
        # Genel Bilgiler
        story.append(Paragraph(f"<b>Muayene Türü:</b> {report.muayene_turu}", styles['Normal']))
        story.append(Paragraph(f"<b>Tarih:</b> {report.tarih}", styles['Normal']))
        story.append(Paragraph(f"<b>Teknisyen:</b> {report.teknisyen}", styles['Normal']))
        story.append(Spacer(1, 0.5*cm))
        
        # Cihaz Bilgileri
        story.append(Paragraph("<b>CİHAZ BİLGİLERİ</b>", styles['Heading2']))
        for key, value in report.cihaz_bilgileri.items():
            story.append(Paragraph(f"<b>{key.replace('_', ' ').title()}:</b> {value}", styles['Normal']))
        story.append(Spacer(1, 0.5*cm))
        
        # Ölçüm Sonuçları
        story.append(Paragraph("<b>ÖLÇÜM SONUÇLARI</b>", styles['Heading2']))
        
        # Tablo oluştur
        data = [["Parametre", "Değer"]]
        for key, value in report.olcum_sonuclari.items():
            data.append([key.replace('_', ' ').title(), str(value)])
        
        table = Table(data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        story.append(table)
        story.append(Spacer(1, 0.5*cm))
        
        # Notlar
        story.append(Paragraph("<b>NOTLAR</b>", styles['Heading2']))
        story.append(Paragraph(report.notlar, styles['Normal']))
        
        # PDF'i kaydet
        doc.build(story)
        
        return FileResponse(
            path=str(pdf_path),
            media_type='application/pdf',
            filename=filename
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF oluşturma hatası: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

