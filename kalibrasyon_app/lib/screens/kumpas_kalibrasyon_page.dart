import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

/// KUMPAS Kalibrasyon Formu
/// Standart şablondan parametreleri çeker ve form oluşturur
/// Düzenleme modu: kalibrasyonId verilirse mevcut kaydı yükler
class KumpasKalibrasyonPage extends StatefulWidget {
  final int? organizasyonId;
  final String? organizasyonAd;
  final int? kalibrasyonId;  // Düzenleme modu için
  final bool editMode;       // Düzenleme modu aktif mi?

  const KumpasKalibrasyonPage({
    Key? key,
    this.organizasyonId,
    this.organizasyonAd,
    this.kalibrasyonId,
    this.editMode = false,
  }) : super(key: key);

  @override
  _KumpasKalibrasyonPageState createState() => _KumpasKalibrasyonPageState();
}

class _KumpasKalibrasyonPageState extends State<KumpasKalibrasyonPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _sablon;
  List<dynamic> _parametreler = [];

  // Cihaz bilgileri
  final _seriNoController = TextEditingController();
  final _markaController = TextEditingController();
  final _modelController = TextEditingController();
  final _olcmeAraligiController = TextEditingController(text: '0-150 mm');
  final _cozunurlukController = TextEditingController(text: '0,02 mm');

  // Çevre koşulları
  final _sicaklikController = TextEditingController(text: '20.0');
  final _nemController = TextEditingController(text: '45.0');

  // Ölçüm verileri - Her parametre için ölçüm değerleri
  Map<String, List<TextEditingController>> _olcumControllers = {};

  // Fonksiyonellik kontrolleri
  Map<String, String> _fonksiyonellik = {
    'olcme_ceneleri': 'Uygun',
    'tespit_vidasi': 'Uygun',
    'gosterge': 'Uygun',
    'tambur_vernier': 'Uygun',
  };

  @override
  void initState() {
    super.initState();
    
    if (widget.editMode && widget.kalibrasyonId != null) {
      _loadExistingKalibrasyon();
    } else {
      _loadTemplate();
    }
  }

  Future<void> _loadExistingKalibrasyon() async {
    try {
      print('🔄 Kalibrasyon yükleniyor: ${widget.kalibrasyonId}');
      
      // Önce şablonu yükle (controller'lar oluşsun)
      await _loadTemplate();
      
      // Mevcut kaydı yükle
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/calibration/kumpas/${widget.kalibrasyonId}'),
      );

      if (response.statusCode != 200) {
        throw Exception('Kalibrasyon kaydı yüklenemedi');
      }

      final data = json.decode(response.body);
      print('✅ Kalibrasyon verisi geldi: ${data['id']}');
      
      setState(() {
        // Cihaz bilgileri
        _markaController.text = data['cihaz']['marka'] ?? '';
        _modelController.text = data['cihaz']['model'] ?? '';
        _seriNoController.text = data['cihaz']['seri_no'] ?? '';
        
        // Çevre koşulları
        _sicaklikController.text = data['sicaklik']?.toString() ?? '';
        _nemController.text = data['nem']?.toString() ?? '';
        
        // Ölçüm verileri
        if (data['olcum_verileri'] != null) {
          final olcumVerileri = data['olcum_verileri'] as Map<String, dynamic>;
          
          olcumVerileri.forEach((kod, degerler) {
            if (_olcumControllers.containsKey(kod) && degerler is List) {
              final controllers = _olcumControllers[kod]!;
              for (int i = 0; i < degerler.length && i < controllers.length; i++) {
                // Değer JSON object ise okunan_deger'i al
                var deger = degerler[i];
                String degerStr = '';
                
                if (deger is Map) {
                  degerStr = deger['okunan_deger']?.toString() ?? '';
                } else {
                  degerStr = deger?.toString() ?? '';
                }
                
                controllers[i].text = degerStr;
              }
              print('✅ $kod parametresi dolduruldu: ${degerler.length} değer');
            }
          });
        }
        
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTemplate() async {
    try {
      // 1. Standartları getir
      final standardsResponse = await http.get(
        Uri.parse('http://localhost:8000/api/standards/kumpas'),
      );

      if (standardsResponse.statusCode != 200) {
        throw Exception('Standart bulunamadı');
      }

      final standardsData = json.decode(standardsResponse.body);
      final sablon = standardsData['standartlar'][0];

      // 2. Parametreleri getir
      final paramsResponse = await http.get(
        Uri.parse(
            'http://localhost:8000/api/templates/${sablon['sablon_id']}/parameters'),
      );

      if (paramsResponse.statusCode != 200) {
        throw Exception('Parametreler bulunamadı');
      }

      final paramsData = json.decode(paramsResponse.body);

      setState(() {
        _sablon = sablon;
        _parametreler = paramsData['parametreler'];
        _initializeControllers();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _initializeControllers() {
    // Her parametre için test nokta sayısı kadar controller oluştur
    for (var param in _parametreler) {
      final kod = param['kod'] as String;
      final testNoktalari = param['test_noktalari'] as List;

      // Sadece ölçüm parametreleri için (fonksiyonellik hariç)
      if (param['tolerans_tipi'] != 'qualitative') {
        _olcumControllers[kod] = List.generate(
          testNoktalari.length,
          (index) => TextEditingController(),
        );
      }
    }
  }

  @override
  void dispose() {
    _seriNoController.dispose();
    _markaController.dispose();
    _modelController.dispose();
    _olcmeAraligiController.dispose();
    _cozunurlukController.dispose();
    _sicaklikController.dispose();
    _nemController.dispose();

    // Tüm ölçüm controller'ları temizle
    _olcumControllers.forEach((key, controllers) {
      controllers.forEach((controller) => controller.dispose());
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KUMPAS Kalibrasyonu'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          if (widget.editMode && widget.kalibrasyonId != null)
            IconButton(
              icon: Icon(Icons.description),
              tooltip: 'Word Sertifikası Oluştur',
              onPressed: _generateWord,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24),
                    _buildCihazBilgileri(),
                    SizedBox(height: 24),
                    _buildCevreKosullari(),
                    SizedBox(height: 24),
                    _buildOlcumParametreleri(),
                    SizedBox(height: 24),
                    _buildFonksiyonellikKontrolleri(),
                    SizedBox(height: 32),
                    _buildKaydetButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.factory, color: Colors.blue.shade700, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.editMode 
                            ? 'Kalibrasyon Düzenle' 
                            : (widget.organizasyonAd ?? 'KUMPAS Kalibrasyon'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _sablon?['standart_kod'] ?? 'MEK.SIT.002',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test noktalarına göre ölçüm değerlerini girin. Sapma otomatik hesaplanacak.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCihazBilgileri() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📏 Cihaz Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _seriNoController,
              decoration: InputDecoration(
                labelText: 'Seri No *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Zorunlu alan' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _markaController,
              decoration: InputDecoration(
                labelText: 'Marka',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _olcmeAraligiController,
                    decoration: InputDecoration(
                      labelText: 'Ölçme Aralığı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cozunurlukController,
                    decoration: InputDecoration(
                      labelText: 'Çözünürlük',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCevreKosullari() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌡️ Çevre Koşulları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sicaklikController,
                    decoration: InputDecoration(
                      labelText: 'Sıcaklık (°C) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thermostat),
                      helperText: 'Önerilen: 20±2°C',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Zorunlu alan' : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nemController,
                    decoration: InputDecoration(
                      labelText: 'Bağıl Nem (%) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water_drop),
                      helperText: 'Önerilen: 45±25%',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Zorunlu alan' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOlcumParametreleri() {
    // Sadece ölçüm parametrelerini filtrele (fonksiyonellik ve çevre koşulları hariç)
    final olcumParams = _parametreler.where((param) {
      final kod = param['kod'] as String;
      return !['olcme_ceneleri', 'tespit_vidasi', 'gosterge', 'tambur_vernier',
              'sicaklik', 'bagli_nem']
          .contains(kod);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Ölçüm Parametreleri',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Referans değerlere göre okuduğunuz değerleri girin',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        SizedBox(height: 16),
        ...olcumParams.map((param) => _buildParametreCard(param)).toList(),
      ],
    );
  }

  Widget _buildParametreCard(Map<String, dynamic> param) {
    final kod = param['kod'] as String;
    final ad = param['ad'] as String;
    final birim = param['birim'] as String;
    final testNoktalari = param['test_noktalari'] as List;
    final zorunlu = param['zorunlu'] as bool;
    final tolerans = param['tolerans_degeri'];

    final controllers = _olcumControllers[kod] ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ad,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                if (zorunlu)
                  Chip(
                    label: Text('Zorunlu',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: Colors.red.shade400,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Tolerans: ±$tolerans $birim',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            SizedBox(height: 12),
            // Test noktaları tablosu
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _tableCell('Nominal\n($birim)', isHeader: true),
                    _tableCell('Ölçülen\n($birim)', isHeader: true),
                    _tableCell('Sapma\n($birim)', isHeader: true),
                  ],
                ),
                // Rows
                ...List.generate(testNoktalari.length, (index) {
                  final referans = testNoktalari[index];
                  
                  return TableRow(
                    children: [
                      _tableCell(referans.toString()),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: controllers[index],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            hintText: referans.toString(),
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: zorunlu
                              ? (value) => value?.isEmpty ?? true
                                  ? 'Gerekli'
                                  : null
                              : null,
                          onChanged: (value) {
                            // Her değişiklikte UI'ı güncelle (sapma hesaplansın)
                            setState(() {});
                          },
                        ),
                      ),
                      // Sapma sütunu (otomatik hesaplanan)
                      _buildSapmaCell(controllers[index], referans, tolerans),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 13 : 14,
        ),
      ),
    );
  }

  Widget _buildSapmaCell(TextEditingController controller, dynamic referans, dynamic tolerans) {
    final okunanText = controller.text;
    
    // Boş ise gösterme
    if (okunanText.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          '-',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sapma hesapla
    final okunan = double.tryParse(okunanText);
    if (okunan == null) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Hata',
          style: TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    final referansDouble = referans is double ? referans : double.parse(referans.toString());
    final sapma = okunan - referansDouble;
    
    // Toleransı geçiyor mu?
    final toleransDouble = tolerans is double ? tolerans : double.parse(tolerans.toString());
    final uygunMu = sapma.abs() <= toleransDouble;
    
    // Renk belirleme
    Color renk;
    if (sapma == 0) {
      renk = Colors.green;
    } else if (uygunMu) {
      renk = Colors.orange;
    } else {
      renk = Colors.red;
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: renk.withOpacity(0.3)),
        ),
        child: Text(
          sapma.toStringAsFixed(3),
          style: TextStyle(
            color: renk,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFonksiyonellikKontrolleri() {
    final fonksiyonParams = _parametreler.where((param) {
      final kod = param['kod'] as String;
      return ['olcme_ceneleri', 'tespit_vidasi', 'gosterge', 'tambur_vernier']
          .contains(kod);
    }).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Fonksiyonellik Kontrolleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...fonksiyonParams.map((param) {
              final kod = param['kod'] as String;
              final ad = param['ad'] as String;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(ad, style: TextStyle(fontSize: 14)),
                    ),
                    ToggleButtons(
                      isSelected: [
                        _fonksiyonellik[kod] == 'Uygun',
                        _fonksiyonellik[kod] == 'Uygun Değil',
                      ],
                      onPressed: (index) {
                        setState(() {
                          _fonksiyonellik[kod] =
                              index == 0 ? 'Uygun' : 'Uygun Değil';
                        });
                      },
                      selectedColor: Colors.white,
                      fillColor: _fonksiyonellik[kod] == 'Uygun'
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Uygun'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Uygun Değil'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildKaydetButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saveCalibration,
        icon: Icon(Icons.save, size: 28),
        label: Text(
          'Kalibrasyonu Kaydet ve Hesapla',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _generateWord() async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Word sertifikası oluşturuluyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/calibration/kumpas/${widget.kalibrasyonId}/generate-word'),
      );

      // Loading'i kapat
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final wordFilename = result['word_filename'];
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(child: Text('Sertifika Hazır')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Word sertifikası başarıyla oluşturuldu.'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wordFilename,
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kapat'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Word dosyasını indir
                  try {
                    final url = 'http://localhost:8000/api/download/word/$wordFilename';
                    
                    // Web tarayıcıda aç
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Word sertifikası indiriliyor...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw 'URL açılamadı';
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('İndirme hatası: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.download),
                label: Text('İndir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Word oluşturma başarısız');
      }
    } catch (e) {
      // Loading açıksa kapat
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCalibration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun')),
      );
      return;
    }

    try {
      // Ölçüm verilerini hazırla
      final payload = {
        'organizasyon_id': widget.organizasyonId,
        'cihaz_seri_no': _seriNoController.text,
        'cihaz_marka': _markaController.text,
        'cihaz_model': _modelController.text,
        'olcme_araligi': _olcmeAraligiController.text,
        'cozunurluk': _cozunurlukController.text,
        'sicaklik': double.parse(_sicaklikController.text),
        'nem': double.parse(_nemController.text),
        'fonksiyonellik': _fonksiyonellik,
      };

      // Her parametre için ölçüm verilerini ekle - olcum_verileri objesi içine
      final olcumVerileri = <String, dynamic>{};
      
      _olcumControllers.forEach((kod, controllers) {
        final param = _parametreler.firstWhere((p) => p['kod'] == kod);
        final testNoktalari = param['test_noktalari'] as List;

        final olcumler = List.generate(controllers.length, (index) {
          final referans = testNoktalari[index];
          final okunanText = controllers[index].text;
          
          // Eğer boşsa referans değerini kullan
          final okunan = okunanText.isNotEmpty 
              ? (double.tryParse(okunanText) ?? referans)
              : referans;
          
          // Sapma hesapla (Okunan - Referans)
          final sapma = okunan - referans;

          return {
            'referans_deger': referans,
            'okunan_deger': okunan,
            'sapma': sapma,
            'belirsizlik': 0.030, // AS KALİBRASYON standardı
          };
        });

        // Sadece dolu ölçümler varsa ekle
        if (olcumler.isNotEmpty && olcumler.any((o) => controllers[olcumler.indexOf(o)].text.isNotEmpty)) {
          olcumVerileri[kod] = olcumler;
        }
      });
      
      // Ölçüm verilerini payload'a ekle
      payload['olcum_verileri'] = olcumVerileri;

      // API'ye gönder (düzenleme veya yeni kayıt)
      final response = widget.editMode && widget.kalibrasyonId != null
          ? await http.put(
              Uri.parse('http://localhost:8000/api/calibration/kumpas/${widget.kalibrasyonId}'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(payload),
            )
          : await http.post(
              Uri.parse('http://localhost:8000/api/calibration/kumpas/create'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(payload),
            );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final kalibrasyonId = result['kalibrasyon_id'];
        
        // Başarı mesajı
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(child: Text('Kayıt Başarılı')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kalibrasyon verileri başarıyla kaydedildi!'),
                SizedBox(height: 12),
                Text('Kalibrasyon ID: $kalibrasyonId'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog kapat
                  Navigator.pop(context, true); // Form sayfasını kapat ve listeyi yenile
                },
                child: Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
