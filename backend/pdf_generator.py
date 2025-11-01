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
        
        # Türkçe font ekle
        pdf.add_font('DejaVu', '', 'C:/Windows/Fonts/DejaVuSans.ttf')
        pdf.add_font('DejaVu', 'B', 'C:/Windows/Fonts/DejaVuSans-Bold.ttf')
        pdf.set_font('DejaVu', '', 10)
        
        # Başlık
        pdf.set_font('DejaVu', 'B', 18)
        pdf.set_text_color(30, 58, 138)
        pdf.cell(0, 10, 'MUAYENE RAPORU', ln=True, align='C')
        pdf.set_font('DejaVu', '', 11)
        pdf.set_text_color(127, 140, 141)
        pdf.cell(0, 8, 'ISO/IEC 17020 Uyumlu Kalibrasyon Raporu', ln=True, align='C')
        pdf.ln(5)
        
        # GENEL BİLGİLER
        pdf.set_font('DejaVu', 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'GENEL BİLGİLER', ln=True, fill=True, border=1)
        pdf.set_font('DejaVu', '', 10)
        pdf.set_text_color(0, 0, 0)
        
        genel_data = [
            ['Rapor No:', rapor_no],
            ['Muayene Türü:', report.muayene_turu],
            ['Tarih:', report.tarih],
            ['Teknisyen:', report.teknisyen],
        ]
        
        for label, value in genel_data:
            pdf.set_fill_color(232, 244, 248)
            pdf.set_font('DejaVu', 'B', 10)
            pdf.cell(50, 8, label, border=1, fill=True)
            pdf.set_font('DejaVu', '', 10)
            pdf.cell(0, 8, value, border=1, ln=True)
        
        pdf.ln(5)
        
        # CİHAZ BİLGİLERİ
        pdf.set_font('DejaVu', 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'CİHAZ BİLGİLERİ', ln=True, fill=True, border=1)
        pdf.set_font('DejaVu', '', 10)
        pdf.set_text_color(0, 0, 0)
        
        cihaz_data = [
            ['Marka:', report.cihaz_bilgileri.get('marka', '-')],
            ['Model:', report.cihaz_bilgileri.get('model', '-')],
            ['Seri No:', report.cihaz_bilgileri.get('seri_no', '-')],
        ]
        
        for label, value in cihaz_data:
            pdf.set_fill_color(232, 244, 248)
            pdf.set_font('DejaVu', 'B', 10)
            pdf.cell(50, 8, label, border=1, fill=True)
            pdf.set_font('DejaVu', '', 10)
            pdf.cell(0, 8, value, border=1, ln=True)
        
        pdf.ln(5)
        
        # GÖRSEL ANALİZ
        if report.gorsel_analiz:
            pdf.set_font('DejaVu', 'B', 12)
            pdf.set_text_color(44, 62, 80)
            pdf.set_fill_color(255, 249, 230)
            pdf.cell(0, 10, 'GÖRSEL ANALİZ SONUÇLARI', ln=True, fill=True, border=1)
            pdf.set_font('DejaVu', '', 10)
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
                pdf.set_font('DejaVu', 'B', 10)
                pdf.cell(50, 8, label, border=1, fill=True)
                pdf.set_font('DejaVu', '', 10)
                pdf.multi_cell(0, 8, value, border=1)
            
            pdf.ln(5)
        
        # ÖLÇÜM SONUÇLARI
        pdf.set_font('DejaVu', 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(248, 249, 250)
        pdf.cell(0, 10, 'ÖLÇÜM SONUÇLARI', ln=True, fill=True, border=1)
        
        # Tablo başlığı
        pdf.set_fill_color(44, 62, 80)
        pdf.set_text_color(255, 255, 255)
        pdf.set_font('DejaVu', 'B', 10)
        pdf.cell(60, 10, 'Parametre', border=1, fill=True)
        pdf.cell(70, 10, 'Ölçülen Değer', border=1, fill=True)
        pdf.cell(60, 10, 'Durum', border=1, fill=True, ln=True)
        
        # Tablo içeriği
        pdf.set_text_color(0, 0, 0)
        pdf.set_font('DejaVu', '', 10)
        for parametre, deger in report.olcum_sonuclari.items():
            pdf.cell(60, 8, parametre, border=1)
            pdf.cell(70, 8, str(deger), border=1)
            pdf.cell(60, 8, 'Normal', border=1, ln=True)
        
        pdf.ln(5)
        
        # NOTLAR
        pdf.set_font('DejaVu', 'B', 12)
        pdf.set_text_color(44, 62, 80)
        pdf.set_fill_color(255, 249, 230)
        pdf.cell(0, 10, 'NOTLAR VE GÖZLEMLER', ln=True, fill=True, border=1)
        pdf.set_font('DejaVu', '', 10)
        pdf.set_text_color(0, 0, 0)
        pdf.multi_cell(0, 6, report.notlar, border=1)
        
        pdf.ln(10)
        
        # İMZA ALANI
        pdf.set_font('DejaVu', 'B', 10)
        pdf.cell(95, 8, 'Muayene Yapan', border=0, align='C')
        pdf.cell(95, 8, 'Onaylayan', border=0, align='C', ln=True)
        pdf.ln(10)
        pdf.set_font('DejaVu', '', 10)
        pdf.cell(95, 8, report.teknisyen, border='T', align='C')
        pdf.cell(95, 8, '_____________________', border='T', align='C', ln=True)
        pdf.cell(95, 6, f'Tarih: {report.tarih}', border=0, align='C')
        pdf.cell(95, 6, 'İmza ve Tarih', border=0, align='C', ln=True)
        
        pdf.ln(10)
        
        # Footer
        pdf.set_font('DejaVu', '', 9)
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

