import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: PersegiApp(), debugShowCheckedModeBanner: false));
}

class PersegiApp extends StatefulWidget {
  const PersegiApp({super.key});

  @override
  @override
  State<PersegiApp> createState() => _PersegiAppState();
}

class _PersegiAppState extends State<PersegiApp> {
  final TextEditingController panjangSisiController = TextEditingController();

  double luas = 0;
  double keliling = 0;

  void hitung() {
    double sisi = double.tryParse(panjangSisiController.text) ?? 0;

    setState(() {
      luas = sisi * 2;
      keliling = sisi * 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hitung Persegi"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.square_outlined, size: 80, color: Colors.black),
            TextField(
              controller: panjangSisiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Panjang Sisi",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: hitung,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
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
