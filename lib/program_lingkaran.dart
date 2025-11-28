import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: LingkaranApp(), debugShowCheckedModeBanner: false));
}

class LingkaranApp extends StatefulWidget {
  const LingkaranApp({super.key});

  @override
  @override
  State<LingkaranApp> createState() => _LingkaranAppState();
}

class _LingkaranAppState extends State<LingkaranApp> {
  final TextEditingController jariController = TextEditingController();
  final TextEditingController diameterController = TextEditingController();

  double luas1 = 0;
  double keliling1 = 0;
  double luas2 = 0;
  double keliling2 = 0;

  void hitung() {
    double diameter = double.tryParse(diameterController.text) ?? 0;
    double jari = double.tryParse(jariController.text) ?? 0;

    setState(() {
      /* Berdasar diameter */
      luas1 = 0.25 * 3.14 * (diameter * diameter);
      keliling1 = 3.14 * diameter;
      /* Berdasar jari-jari */
      luas2 = 3.14 * (jari * jari);
      keliling2 = 2 * 3.14 * jari;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hitung Lingkaran"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.circle_outlined, size: 80, color: Colors.blueAccent),
            Text(
              "data dari diameter atau jari-jari. Isi salah satu, jangan keduanya.",
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: jariController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jari-Jari",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: diameterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Diameter",
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
              "Luas (Berdasar Diameter): $luas1",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Keliling (Berdasar Diameter): $keliling1",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Luas (Berdasar Jari-Jari): $luas2",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Keliling (Berdasar Jari-Jari): $keliling2",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
