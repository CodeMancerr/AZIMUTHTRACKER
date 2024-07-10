import 'package:flutter/material.dart';
import 'map_tracker.dart';

//Program ini merupakan kelas dalam Flutter yang digunakan untuk membuat halaman depan (home screen) dari sebuah aplikasi.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

//Program ini digunakan untuk menghitung dan menampilkan azimuth dan back azimuth berdasarkan input dari pengguna.
class _HomeScreenState extends State<HomeScreen> {
  TextEditingController azimuthController = TextEditingController();
  double? azimuth;
  double? backAzimuth;

  @override
  void dispose() {
    azimuthController.dispose();
    super.dispose();
  }

  void calculateBackAzimuth() {
    if (azimuthController.text.isNotEmpty) {
      double inputAzimuth = double.tryParse(azimuthController.text) ?? 0.0;
      backAzimuth = (inputAzimuth + 180.0) % 360.0;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Back Azimuth Tracker',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: azimuthController,
                keyboardType: TextInputType.number,
                style:
                    TextStyle(color: Colors.black), // Set text color to black
                decoration: InputDecoration(
                  labelText: 'Enter Azimuth (degrees)',
                  labelStyle: TextStyle(
                      color: Colors.black), // Set label text color to black
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                calculateBackAzimuth();
                if (backAzimuth != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapTracker(backAzimuth!),
                    ),
                  );
                }
              },
              child: Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
