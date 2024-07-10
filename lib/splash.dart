import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

//Program ini adalah aplikasi yang menggunakan class SplashScreen sebagai widget yang memiliki state. Widget ini menampilkan layar pembuka sementara (splash screen) saat aplikasi pertama kali dijalankan. Biasanya, splash screen digunakan untuk menampilkan logo atau branding aplikasi selama beberapa detik sebelum pengguna diarahkan ke halaman utama aplikasi.
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

//Program ini digunakan untuk menampilkan layar pembuka (splash screen) dengan animasi pada aplikasi.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

//Program ini menginisialisasi animasi dan menavigasi pengguna ke layar beranda setelah penundaan tiga detik.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeIn,
    );

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

//Program ini digunakan untuk membersihkan dan membuang sumber daya yang tidak diperlukan lagi saat suatu objek dihapus.
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

//Program ini menampilkan gambar dengan efek transisi pudar (fade transition) yang ukurannya menyesuaikan dengan ukuran layar perangkat.
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar perangkat
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation!,
          child: Image.asset(
            'assets/images/aztra_logo_dalam.png', // ganti dengan path gambar Anda
            width: size.width, // menyesuaikan lebar gambar dengan lebar layar
            height:
                size.height, // menyesuaikan tinggi gambar dengan tinggi layar
            fit: BoxFit.contain, // menyesuaikan ukuran gambar
          ),
        ),
      ),
    );
  }
}
