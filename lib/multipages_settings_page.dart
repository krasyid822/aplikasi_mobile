import 'package:flutter/material.dart';

class Multipages_SettingsPage extends StatelessWidget {
  const Multipages_SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Page'),
      ),
      body: const Center(
        child: Text(
          'Ini adalah halaman Settings.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}