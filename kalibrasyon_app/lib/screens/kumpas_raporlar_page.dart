import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// KUMPAS Kalibrasyon Raporları Listesi
class KumpasRaporlarPage extends StatefulWidget {
  @override
  _KumpasRaporlarPageState createState() => _KumpasRaporlarPageState();
}

class _KumpasRaporlarPageState extends State<KumpasRaporlarPage> {
  List<Map<String, dynamic>> _raporlar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRaporlar();
  }

  Future<void> _loadRaporlar() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/calibration/kumpas/list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _raporlar = List<Map<String, dynamic>>.from(data['kalibrasyonlar']);
          _isLoading = false;
        });
      } else {
        throw Exception('Raporlar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadWord(String filename) async {
    try {
      final url = 'http://localhost:8000/api/download/word/$filename';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word belgesi indiriliyor...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'URL açılamadı';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KUMPAS Kalibrasyon Raporları'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRaporlar,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _raporlar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz KUMPAS raporu bulunmuyor',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.add),
                        label: Text('Yeni Kalibrasyon Oluştur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRaporlar,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _raporlar.length,
                    itemBuilder: (context, index) {
                      final rapor = _raporlar[index];
                      final createdAt = DateTime.parse(rapor['created_at']);
                      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
                      final uygunluk = rapor['uygunluk'] as bool;
                      final wordFilename = rapor['word_filename'];

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: uygunluk ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık satırı
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: uygunluk ? Colors.green[100] : Colors.red[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          uygunluk ? Icons.check_circle : Icons.error,
                                          color: uygunluk ? Colors.green[700] : Colors.red[700],
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          uygunluk ? 'UYGUN' : 'UYGUN DEĞİL',
                                          style: TextStyle(
                                            color: uygunluk ? Colors.green[900] : Colors.red[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Sertifika No
                              Text(
                                rapor['sertifika_no'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              
                              // Müşteri bilgisi
                              Row(
                                children: [
                                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      rapor['organizasyon']['musteri_adi'] ?? rapor['organizasyon']['ad'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 6),
                              
                              // Cihaz bilgisi
                              Row(
                                children: [
                                  Icon(Icons.precision_manufacturing, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${rapor['cihaz']['marka']} ${rapor['cihaz']['model']} (S/N: ${rapor['cihaz']['seri_no']})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12),
                              Divider(),
                              SizedBox(height: 8),
                              
                              // Aksiyon butonları
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (wordFilename != null) ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _downloadWord(wordFilename),
                                      icon: Icon(Icons.download, size: 18),
                                      label: Text('Word İndir'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                                          SizedBox(width: 6),
                                          Text(
                                            'Word bulunamadı',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      // Düzenleme sayfasına git
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/kumpas_kalibrasyon',
                                        arguments: {
                                          'kalibrasyon_id': rapor['id'],
                                          'edit_mode': true,
                                        },
                                      );
                                      
                                      // Sayfa geri dönünce listeyi yenile
                                      if (result == true) {
                                        _loadRaporlar();
                                      }
                                    },
                                    icon: Icon(Icons.edit_outlined, size: 18),
                                    label: Text('Düzenle'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange[700],
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.add),
        label: Text('Yeni Kalibrasyon'),
        backgroundColor: Colors.green[600],
      ),
    );
  }
}
