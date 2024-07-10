import 'package:flutter/material.dart';
import 'splash.dart';

void main() {
  runApp(const MainApp());
}

//Program ini adalah aplikasi Flutter yang menampilkan halaman pembuka (splash screen) sebagai layar utama tanpa menampilkan banner debug.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      home: SplashScreen(),
    );
  }
}
