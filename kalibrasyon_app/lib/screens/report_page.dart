import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';

class ReportPage extends StatelessWidget {
  final String pdfPath; // Base64 string
  final String transcribedText;
  final Map<String, dynamic> reportData;

  const ReportPage({
    super.key,
    required this.pdfPath,
    required this.transcribedText,
    required this.reportData,
  });

  Future<void> _openPdf() async {
    try {
      final bytes = base64Decode(pdfPath);
      
      if (kIsWeb) {
        // Web için - data URL kullanarak aç
        final dataUrl = 'data:application/pdf;base64,$pdfPath';
        final uri = Uri.parse(dataUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else {
        // Desktop/Mobile için - geçici dosyaya kaydet ve aç
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/kalibrasyon_raporu_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);
        
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      print('PDF açma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Rapor Hazır',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 120,
                color: Colors.green,
              ),
              const SizedBox(height: 40),
              const Text(
                'Rapor Başarıyla Oluşturuldu!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transkripsiyon:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      transcribedText.isEmpty
                          ? 'Metin bulunamadı'
                          : transcribedText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _openPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'PDF\'i Aç',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Ana Sayfaya Dön',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

