"""
KUMPAS şablonunu test et - Basit ve hızlı
"""
import asyncio
from database import AsyncSessionLocal
from standards_models import CalibrasyonStandardi, StandardSablon, SablonParametre
from sqlalchemy import select


async def test_kumpas():
    async with AsyncSessionLocal() as db:
        # 1. Standardı bul
        result = await db.execute(
            select(CalibrasyonStandardi).where(CalibrasyonStandardi.kod == "MEK.SIT.002")
        )
        standart = result.scalar_one_or_none()
        
        if not standart:
            print("❌ HATA: MEK.SIT.002 standardı bulunamadı!")
            return
        
        print(f"✅ Standart bulundu: {standart.ad_tr}")
        print(f"   Organizasyon: {standart.organizasyon}")
        print(f"   Yıl: {standart.yil}")
        print()
        
        # 2. Şablonu bul
        result = await db.execute(
            select(StandardSablon).where(StandardSablon.standart_id == standart.id)
        )
        sablon = result.scalar_one_or_none()
        
        if not sablon:
            print("❌ HATA: KUMPAS şablonu bulunamadı!")
            return
        
        print(f"✅ Şablon bulundu: {sablon.cihaz_tipi_adi}")
        print(f"   Cihaz Tipi Kodu: {sablon.cihaz_tipi_kodu}")
        print(f"   Kalibrasyon Süresi: {sablon.kalibrasyon_suresi_ay} ay")
        print()
        
        # 3. Parametreleri listele
        result = await db.execute(
            select(SablonParametre).where(SablonParametre.sablon_id == sablon.id)
        )
        parametreler = result.scalars().all()
        
        print(f"✅ Toplam {len(parametreler)} parametre bulundu:")
        print()
        
        for i, param in enumerate(parametreler, 1):
            print(f"{i}. {param.parametre_adi}")
            print(f"   Kod: {param.parametre_kodu}")
            print(f"   Birim: {param.birim}")
            print(f"   Tolerans: {param.tolerans_tipi} - {param.tolerans_degeri}")
            print(f"   Test Noktaları: {param.test_noktalari}")
            print(f"   Zorunlu: {'✅ Evet' if param.zorunlu else '❌ Hayır'}")
            print()
        
        print("=" * 60)
        print("🎉 TEST BAŞARILI! KUMPAS şablonu tamam.")
        print("=" * 60)


if __name__ == "__main__":
    asyncio.run(test_kumpas())
