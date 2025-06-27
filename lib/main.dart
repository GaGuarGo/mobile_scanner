import 'package:cam_scanner_test/features/biometry/biometry_view.dart';
import 'package:cam_scanner_test/features/biometry/faces_view.dart';
import 'package:cam_scanner_test/features/biometry/widgets/preview_image.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:cam_scanner_test/features/home/home_page.dart';
import 'package:cam_scanner_test/features/document_scanner/scanner_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
        ),
      ),
      initialRoute: '/home',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/home': (context) => HomePage(),
        //? Face biometry related routes
        '/faces': (context) => const FacesView(),
        '/biometry': (context) => BiometryView(),
        '/preview-image': (context) => const PreviewImage(),
        //? Document scanner related routes
        '/scanner': (context) => ScannerPage(),
      },
    );
  }
}
