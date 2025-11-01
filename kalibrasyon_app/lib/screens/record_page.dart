import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'report_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:async';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasRecording = false;
  String _transcribedText = '';
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _recordedChunks = [];
  html.Blob? _audioBlob;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      
      _mediaRecorder = html.MediaRecorder(stream);
      _recordedChunks.clear();
      
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      });
      
      _mediaRecorder!.addEventListener('stop', (event) {
        _audioBlob = html.Blob(_recordedChunks, 'audio/webm');
      });
      
      _mediaRecorder!.start();
      
      setState(() {
        _isRecording = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses kaydı başladı - konuşmaya başlayabilirsiniz!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mikrofon erişimi reddedildi: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_mediaRecorder != null) {
      _mediaRecorder!.stop();
      _mediaRecorder!.stream!.getTracks().forEach((track) => track.stop());
      
      // Kaydın tamamlanması için kısa bir süre bekle
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses kaydı tamamlandı! Şimdi rapor oluşturabilirsiniz.')),
      );
    }
  }

  Future<void> _createReport() async {
    if (!_hasRecording || _audioBlob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce ses kaydı yapmalısınız!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Ses dosyasını metne çevir (Whisper)
      final formData = html.FormData();
      formData.appendBlob('file', _audioBlob!, 'recording.webm');
      
      final xhr = html.HttpRequest();
      xhr.open('POST', 'http://localhost:8000/api/speech-to-text');
      
      final completer = Completer<String>();
      
      xhr.onLoad.listen((event) {
        if (xhr.status == 200) {
          completer.complete(xhr.responseText!);
        } else {
          completer.completeError('Transkripsiyon hatası: ${xhr.status}');
        }
      });
      
      xhr.onError.listen((event) {
        completer.completeError('Network hatası');
      });
      
      xhr.send(formData);
      
      final transcriptionText = await completer.future;
      final transcriptionData = json.decode(transcriptionText);
      _transcribedText = transcriptionData['text'] ?? '';
      
      if (_transcribedText.isEmpty) {
        throw Exception('Ses kaydından metin çıkarılamadı');
      }
      
      // 2. Rapor oluştur (GPT-4o-mini ile)
      final reportResponse = await http.post(
        Uri.parse('http://localhost:8000/api/generate-report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': _transcribedText}),
      );
      
      if (reportResponse.statusCode != 200) {
        throw Exception('Rapor oluşturulamadı: ${reportResponse.statusCode}');
      }
      
      final reportData = json.decode(reportResponse.body);

      // 3. PDF oluştur
      final pdfResponse = await http.post(
        Uri.parse('http://localhost:8000/api/create-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reportData),
      );

      if (pdfResponse.statusCode != 200) {
        throw Exception('PDF oluşturulamadı: ${pdfResponse.statusCode}');
      }

      // PDF'i base64 olarak kaydet (web için)
      final pdfBytes = pdfResponse.bodyBytes;
      final pdfBase64 = base64Encode(pdfBytes);

      setState(() {
        _isProcessing = false;
      });

      // Rapor sayfasına git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPage(
            pdfPath: pdfBase64,
            transcribedText: _transcribedText,
            reportData: reportData,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text(
          'Ses Kaydı - Hot Reload Test!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Rapor oluşturuluyor...',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 150,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 40),
                  if (_isRecording)
                    const Text(
                      'Kayıt Yapılıyor...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic, size: 30),
                        const SizedBox(width: 10),
                        Text(
                          _isRecording ? 'Kaydı Durdur' : 'Kayda Başla',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (!_isRecording && _hasRecording) ...[
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _createReport,
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
                          Icon(Icons.description, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'Rapor Oluştur',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

