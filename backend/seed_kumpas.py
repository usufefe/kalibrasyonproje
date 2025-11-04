"""
KUMPAS için MEK.SIT.002 standardına göre kalibrasyon şablonu
AS KALİBRASYON örneğine göre hazırlanmıştır
"""
import asyncio
from database import AsyncSessionLocal
from standards_models import CalibrasyonStandardi, StandardSablon, SablonParametre


async def seed_kumpas_standard():
    """Kumpas kalibrasyon standardı ve şablonunu yükle"""
    
    async with AsyncSessionLocal() as db:
        # 1. MEK.SIT.002 Standardı
        standart = CalibrasyonStandardi(
            kod="MEK.SIT.002",
            ad_tr="Kumpas Standardı iş talimatı",
            ad_en="Caliper Calibration Standard Work Instruction",
            organizasyon="AS KALİBRASYON",
            yil=2022,
            aciklama="Kumpas kalibrasyonu için standart prosedür (0-150mm, 0-200mm, 0-300mm)",
            varsayilan_kalibrasyon_suresi_ay=12,
            varsayilan_sicaklik_min=18.0,
            varsayilan_sicaklik_max=22.0,
            varsayilan_nem_min=20.0,
            varsayilan_nem_max=70.0
        )
        db.add(standart)
        await db.flush()
        
        # 2. Kumpas Şablonu (0-150mm için)
        kumpas = StandardSablon(
            standart_id=standart.id,
            cihaz_tipi_kodu="kumpas",
            cihaz_tipi_adi="Kumpas (Dijital/Analog)",
            grup="Uzunluk Ölçüm Cihazları",
            referans="MEK.SIT.002 - Kumpas Kalibrasyon Prosedürü",
            kalibrasyon_suresi_ay=12
        )
        db.add(kumpas)
        await db.flush()
        
        # 3. KUMPAS PARAMETRELERİ
        
        # Ana Dış Ölçüm Parametreleri (En Önemli!)
        dis_olcum = {
            "parametre_adi": "Dış Ölçüm (External Measurement)",
            "parametre_kodu": "dis_olcum",
            "birim": "mm",
            "tolerans_tipi": "absolute",
            "tolerans_degeri": 0.02,  # ±0.02mm
            "test_noktalari": [0.00, 25.00, 50.00, 75.00, 100.00, 150.00],
            "zorunlu": True,
            "referans": "AS KALİBRASYON Rapor AB-0068-K - Dış Ölçüm Kolonu",
            "aciklama": "Granit pleyt ve mastar bloğu ile dış çene ölçümü"
        }
        
        ic_olcum = {
            "parametre_adi": "İç Ölçüm (Internal Measurement)",
            "parametre_kodu": "ic_olcum",
            "birim": "mm",
            "tolerans_tipi": "absolute",
            "tolerans_degeri": 0.02,
            "test_noktalari": [0.00, 20.00, 25.00],
            "zorunlu": True,
            "referans": "AS KALİBRASYON Rapor - İç Çap Ölçüm",
            "aciklama": "Halka master ile iç çene ölçümü"
        }
        
        orta_olcum = {
            "parametre_adi": "Orta Ölçüm (Middle Position)",
            "parametre_kodu": "orta_olcum",
            "birim": "mm",
            "tolerans_tipi": "absolute",
            "tolerans_degeri": 0.02,
            "test_noktalari": [0.00, 25.00],
            "zorunlu": False,
            "referans": "AS KALİBRASYON Rapor - Orta Konum",
            "aciklama": "Çenenin orta noktasından ölçüm"
        }
        
        derinlik_olcum = {
            "parametre_adi": "Derinlik Ölçümü (Depth Measurement)",
            "parametre_kodu": "derinlik_olcum",
            "birim": "mm",
            "tolerans_tipi": "absolute",
            "tolerans_degeri": 0.04,  # Derinlikte tolerans daha geniş
            "test_noktalari": [25.00],
            "zorunlu": True,
            "referans": "AS KALİBRASYON Rapor Sayfa 3/3",
            "aciklama": "Derinlik çubuğu ile ölçüm"
        }
        
        kademe_olcum = {
            "parametre_adi": "Kademe Ölçümü (Step Measurement)",
            "parametre_kodu": "kademe_olcum",
            "birim": "mm",
            "tolerans_tipi": "absolute",
            "tolerans_degeri": 0.02,
            "test_noktalari": [25.00],
            "zorunlu": True,
            "referans": "AS KALİBRASYON Rapor Sayfa 3/3",
            "aciklama": "Kademe yüksekliği ölçümü"
        }
        
        # Fonksiyonellik Kontrolleri
        fonksiyon_cene = {
            "parametre_adi": "Ölçme Çeneleri Kontrolü",
            "parametre_kodu": "olcme_ceneleri",
            "birim": "Uygun/Uygun Değil",
            "tolerans_tipi": "qualitative",
            "tolerans_degeri": None,
            "test_noktalari": ["visual_check"],
            "zorunlu": True,
            "referans": "Fonksiyonellik Kontrolü",
            "aciklama": "Çenelerin hasar, aşınma kontrolü"
        }
        
        fonksiyon_tespit = {
            "parametre_adi": "Tespit/Tutma Vidası Kontrolü",
            "parametre_kodu": "tespit_vidasi",
            "birim": "Uygun/Uygun Değil",
            "tolerans_tipi": "qualitative",
            "tolerans_degeri": None,
            "test_noktalari": ["functional_check"],
            "zorunlu": True,
            "referans": "Fonksiyonellik Kontrolü",
            "aciklama": "Vida ve kilitleme mekanizması kontrolü"
        }
        
        fonksiyon_gosterge = {
            "parametre_adi": "Gösterge Kontrolü",
            "parametre_kodu": "gosterge",
            "birim": "Uygun/Uygun Değil",
            "tolerans_tipi": "qualitative",
            "tolerans_degeri": None,
            "test_noktalari": ["display_check"],
            "zorunlu": True,
            "referans": "Fonksiyonellik Kontrolü",
            "aciklama": "Dijital ekran veya analog skala okunabilirliği"
        }
        
        fonksiyon_tambur = {
            "parametre_adi": "Tambur ve Vernier Boşluğu",
            "parametre_kodu": "tambur_vernier",
            "birim": "Uygun/Uygun Değil",
            "tolerans_tipi": "qualitative",
            "tolerans_degeri": None,
            "test_noktalari": ["clearance_check"],
            "zorunlu": True,
            "referans": "Fonksiyonellik Kontrolü",
            "aciklama": "Hareket kolaylığı ve boşluk kontrolü"
        }
        
        # Çevre Koşulları
        sicaklik = {
            "parametre_adi": "Ortam Sıcaklığı",
            "parametre_kodu": "sicaklik",
            "birim": "°C",
            "tolerans_tipi": "range",
            "tolerans_degeri": 2.0,  # 20±2°C
            "test_noktalari": [20.0],
            "zorunlu": True,
            "referans": "Kalibrasyon Çevre Şartları",
            "aciklama": "Kalibrasyon sırasında ortam sıcaklığı"
        }
        
        nem = {
            "parametre_adi": "Bağıl Nem",
            "parametre_kodu": "bagli_nem",
            "birim": "%",
            "tolerans_tipi": "range",
            "tolerans_degeri": 25.0,  # %45±25
            "test_noktalari": [45.0],
            "zorunlu": True,
            "referans": "Kalibrasyon Çevre Şartları",
            "aciklama": "Kalibrasyon sırasında bağıl nem oranı"
        }
        
        # Tüm parametreleri ekle
        parametreler = [
            dis_olcum,
            ic_olcum,
            orta_olcum,
            derinlik_olcum,
            kademe_olcum,
            fonksiyon_cene,
            fonksiyon_tespit,
            fonksiyon_gosterge,
            fonksiyon_tambur,
            sicaklik,
            nem
        ]
        
        for param in parametreler:
            db.add(SablonParametre(
                sablon_id=kumpas.id,
                parametre_adi=param["parametre_adi"],
                parametre_kodu=param["parametre_kodu"],
                birim=param["birim"],
                tolerans_tipi=param["tolerans_tipi"],
                tolerans_degeri=param["tolerans_degeri"],
                test_noktalari=param["test_noktalari"],
                zorunlu=param["zorunlu"],
                referans=param["referans"]
            ))
        
        await db.commit()
        
        print("✅ KUMPAS standardı başarıyla yüklendi!")
        print(f"   📏 Standart: {standart.kod} - {standart.ad_tr}")
        print(f"   📊 Toplam Parametre: {len(parametreler)}")
        print(f"   🔢 Ölçüm Parametreleri:")
        print(f"      • Dış Ölçüm: {len(dis_olcum['test_noktalari'])} test noktası")
        print(f"      • İç Ölçüm: {len(ic_olcum['test_noktalari'])} test noktası")
        print(f"      • Derinlik: {len(derinlik_olcum['test_noktalari'])} test noktası")
        print(f"      • Kademe: {len(kademe_olcum['test_noktalari'])} test noktası")
        print(f"   ✅ Fonksiyonellik: 4 kontrol")
        print(f"   🌡️  Çevre Şartları: Sıcaklık ve Nem")


async def main():
    """Ana çalıştırma fonksiyonu"""
    print("🔧 KUMPAS Kalibrasyon Standardı Yükleniyor...")
    print()
    
    await seed_kumpas_standard()
    
    print()
    print("🎉 Tamamlandı! Artık KUMPAS için tam şablon hazır.")
    print()
    print("📋 Sonraki Adımlar:")
    print("   1. Flutter'da form ekranı oluştur")
    print("   2. API'ye veri gönder")
    print("   3. PDF generator'ı bu formata göre düzenle")


if __name__ == "__main__":
    asyncio.run(main())
