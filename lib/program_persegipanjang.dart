import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: PersegiPanjangApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class PersegiPanjangApp extends StatefulWidget {
  const PersegiPanjangApp({super.key});

  @override
  _PersegiPanjangAppState createState() => _PersegiPanjangAppState();
}

class _PersegiPanjangAppState extends State<PersegiPanjangApp> {
  final TextEditingController panjangController = TextEditingController();
  final TextEditingController lebarController = TextEditingController();

  double luas = 0;
  double keliling = 0;

  void hitung() {
    double panjang = double.tryParse(panjangController.text) ?? 0;
    double lebar = double.tryParse(lebarController.text) ?? 0;

    setState(() {
      luas = panjang * lebar;
      keliling = 2 * (panjang + lebar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hitung Persegi Panjang"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.rectangle_outlined, size: 80, color: Colors.blueAccent),
            TextField(
              controller: panjangController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Panjang",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: lebarController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Lebar",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: hitung,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text("Hitung"),
            ),
            SizedBox(height: 20),
            Text(
              "Luas: $luas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Keliling: $keliling",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}