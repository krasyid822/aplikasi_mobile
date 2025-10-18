import 'package:flutter/material.dart';
import 'multipages_home_page.dart';
import 'multipages_about_page.dart';
import 'multipages_settings_page.dart';
import 'multipages_product_page.dart';

void main() {
  runApp(const MultipagesApp());
}

class MultipagesApp extends StatelessWidget {
  const MultipagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiPages App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 68, 221)),
      ),
      home: const Multipages_HomePage(),
      routes: {
        '/multipages_about': (context) => const Multipages_AboutPage(),
        '/multipages_settings': (context) => const Multipages_SettingsPage(),
        '/multipages_product': (context) => const Multipages_ProductPage (),
      },
    );
  }
}
