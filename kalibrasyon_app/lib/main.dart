import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/organizasyon_list_page.dart';
import 'screens/organizasyon_detay_page.dart';
import 'screens/kalibrasyon_form_page.dart';
import 'screens/yeni_organizasyon_page.dart';
import 'screens/raporlar_page.dart';
import 'screens/standart_secim_page.dart';
import 'screens/kumpas_kalibrasyon_page.dart';
import 'screens/kumpas_raporlar_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalibrasyon Yönetim Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: OrganizasyonListPage(), // Yeni ana sayfa
      onGenerateRoute: (settings) {
        if (settings.name == '/standart-secim') {
          final cihaz = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => StandartSecimPage(cihaz: cihaz),
          );
        }
        return null;
      },
      routes: {
        '/home': (context) => HomePage(),
        '/organizasyonlar': (context) => OrganizasyonListPage(),
        '/organizasyon-detay': (context) => OrganizasyonDetayPage(),
        '/kalibrasyon-form': (context) => KalibrasyonFormPage(),
        '/yeni-organizasyon': (context) => YeniOrganizasyonPage(),
        '/raporlar': (context) => RaporlarPage(),
        '/kumpas_kalibrasyon': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          
          // Düzenleme modu
          if (args != null && args.containsKey('kalibrasyon_id')) {
            return KumpasKalibrasyonPage(
              kalibrasyonId: args['kalibrasyon_id'],
              editMode: args['edit_mode'] ?? true,
            );
          }
          
          // Yeni kayıt modu
          return KumpasKalibrasyonPage(
            organizasyonId: args?['organizasyonId'],
            organizasyonAd: args?['organizasyonAd'],
          );
        },
        '/kumpas_raporlar': (context) => KumpasRaporlarPage(),
      },
    );
  }
}
