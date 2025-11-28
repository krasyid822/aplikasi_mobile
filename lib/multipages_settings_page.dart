import 'package:flutter/material.dart';

class MultipagesSettingsPage extends StatelessWidget {
  const MultipagesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Page')),
      body: const Center(
        child: Text(
          'Ini adalah halaman Settings.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
