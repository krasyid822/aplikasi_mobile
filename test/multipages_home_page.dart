import 'package:flutter/material.dart';

class Multipages_HomePage extends StatelessWidget {
  const Multipages_HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'multipages_about') {
                Navigator.pushNamed(context, '/multipages_about');
              } else if (value == 'multipages_settings') {
                Navigator.pushNamed(context, '/multipages_settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'multipages_about',
                child: Text('About'),
              ),
              const PopupMenuItem(
                value: 'multipages_settings',
                child: Text('Settings'),
              ),
            ],
          )
       ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/multipages_about');
          },
          child: const Text('Go to About Page'),
        ),
      ),
    );
  }
}