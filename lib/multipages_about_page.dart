import 'package:flutter/material.dart';

class MultipagesAboutPage extends StatelessWidget {
  const MultipagesAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Page')),
      body: const Center(
        child: Text(
          'Ini adalah halaman About.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
