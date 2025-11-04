"""
KUMPAS API'lerini test et
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_get_standards():
    """1. KUMPAS için standartları getir"""
    print("=" * 60)
    print("TEST 1: KUMPAS Standartlarını Getir")
    print("=" * 60)
    
    response = requests.get(f"{BASE_URL}/api/standards/kumpas")
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ {len(data['standartlar'])} standart bulundu:")
        for std in data['standartlar']:
            print(f"   - {std['standart_kod']}: {std['standart_ad']}")
            print(f"     Şablon ID: {std['sablon_id']}")
        return data['standartlar'][0]['sablon_id'] if data['standartlar'] else None
    else:
        print(f"❌ Hata: {response.text}")
        return None


def test_get_parameters(template_id):
    """2. Şablon parametrelerini getir"""
    print("\n" + "=" * 60)
    print(f"TEST 2: Şablon {template_id} Parametrelerini Getir")
    print("=" * 60)
    
    response = requests.get(f"{BASE_URL}/api/templates/{template_id}/parameters")
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ {len(data['parametreler'])} parametre bulundu:")
        for param in data['parametreler']:
            print(f"\n   📊 {param['ad']}")
            print(f"      Kod: {param['kod']}")
            print(f"      Birim: {param['birim']}")
            print(f"      Tolerans: {param['tolerans_tipi']} - {param['tolerans_degeri']}")
            print(f"      Test Noktaları: {param['test_noktalari']}")
            print(f"      Zorunlu: {'✅' if param['zorunlu'] else '❌'}")
    else:
        print(f"❌ Hata: {response.text}")


def test_create_calibration():
    """3. KUMPAS kalibrasyon kaydı oluştur"""
    print("\n" + "=" * 60)
    print("TEST 3: KUMPAS Kalibrasyon Kaydı Oluştur")
    print("=" * 60)
    
    # AS KALİBRASYON raporundaki örnek veri
    payload = {
        "organizasyon_id": 1,  # Organizasyon ID (önceden var olmalı)
        "cihaz_seri_no": "03476",
        "cihaz_marka": "QUINGDAO",
        "cihaz_model": "Digital Caliper",
        "olcme_araligi": "0-150 mm",
        "cozunurluk": "0,02 mm",
        
        # Dış Ölçüm (AS KALİBRASYON raporundan)
        "dis_olcum": [
            {"referans_deger": 0.00, "okunan_deger": 0.00, "belirsizlik": 0.030},
            {"referans_deger": 25.00, "okunan_deger": 25.00, "belirsizlik": 0.030},
            {"referans_deger": 50.00, "okunan_deger": 50.00, "belirsizlik": 0.030},
            {"referans_deger": 75.00, "okunan_deger": 75.00, "belirsizlik": 0.030},
            {"referans_deger": 100.00, "okunan_deger": 99.98, "belirsizlik": 0.031},
            {"referans_deger": 150.00, "okunan_deger": 149.98, "belirsizlik": 0.031}
        ],
        
        # İç Ölçüm
        "ic_olcum": [
            {"referans_deger": 20.00, "okunan_deger": 20.02, "belirsizlik": 0.030}
        ],
        
        # Derinlik Ölçüm
        "derinlik_olcum": [
            {"referans_deger": 25.00, "okunan_deger": 24.96, "belirsizlik": 0.030}
        ],
        
        # Kademe Ölçüm
        "kademe_olcum": [
            {"referans_deger": 25.00, "okunan_deger": 24.98, "belirsizlik": 0.030}
        ],
        
        # Fonksiyonellik Kontrolü
        "fonksiyonellik": {
            "olcme_ceneleri": "Uygun",
            "tespit_vidasi": "Uygun",
            "gosterge": "Uygun",
            "tambur_vernier": "Uygun"
        },
        
        # Çevre Şartları
        "sicaklik": 20.0,
        "nem": 45.0,
        
        # Referans Cihazlar
        "referans_cihazlar": [
            {"ad": "Granit Pleyt", "imalat": "QUINGDAO", "seri_no": "26087294", "izlenebilirlik": "AB-0002-K"},
            {"ad": "Mastar Seti (46 Parça)", "imalat": "ACCUD", "seri_no": "160017", "izlenebilirlik": "AB-0012-K"}
        ],
        
        "notlar": "AS KALİBRASYON örnek veri - VDI/VDE/DGQ 2618 bölüm 9.1'e göre UYGUN"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/calibration/kumpas/create",
        json=payload,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Kalibrasyon kaydı oluşturuldu!")
        print(f"   ID: {data['kalibrasyon_id']}")
        print(f"   Cihaz ID: {data['cihaz_id']}")
        print(f"   Uygunluk: {data['uygunluk_mesaji']}")
        print(f"\n   📊 Hesaplanan Sapmalar (Dış Ölçüm):")
        for olcum in data['hesaplanan_sapmalar']['dis_olcum']:
            print(f"      {olcum['referans']} mm → {olcum['okunan']} mm = Sapma: {olcum['sapma']} mm")
        return data['kalibrasyon_id']
    else:
        print(f"❌ Hata: {response.text}")
        return None


def test_get_calibration(kalibrasyon_id):
    """4. Kalibrasyon kaydını getir"""
    print("\n" + "=" * 60)
    print(f"TEST 4: Kalibrasyon {kalibrasyon_id} Detayını Getir")
    print("=" * 60)
    
    response = requests.get(f"{BASE_URL}/api/calibration/kumpas/{kalibrasyon_id}")
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Kalibrasyon detayı:")
        print(f"   Organizasyon: {data['organizasyon']['ad']}")
        print(f"   Cihaz: {data['cihaz']['marka']} - Seri: {data['cihaz']['seri_no']}")
        print(f"   Sıcaklık: {data['sicaklik']}°C")
        print(f"   Nem: {data['nem']}%")
        print(f"   Uygunluk: {'✅ UYGUN' if data['uygunluk'] else '❌ UYGUN DEĞİL'}")
        print(f"   Durum: {data['durum']}")
    else:
        print(f"❌ Hata: {response.text}")


if __name__ == "__main__":
    print("\n🔧 KUMPAS API TEST SUITE")
    print("=" * 60)
    
    # 1. Standartları getir
    template_id = test_get_standards()
    
    if template_id:
        # 2. Parametreleri getir
        test_get_parameters(template_id)
    
    # 3. Kalibrasyon oluştur
    kalibrasyon_id = test_create_calibration()
    
    if kalibrasyon_id:
        # 4. Kalibrasyon detayını getir
        test_get_calibration(kalibrasyon_id)
    
    print("\n" + "=" * 60)
    print("🎉 TEST TAMAMLANDI!")
    print("=" * 60)
