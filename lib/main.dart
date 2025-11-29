import 'package:aplikasi_mobile/proyek_uas_main.dart';
import 'package:flutter/material.dart';
import 'program_persegipanjang.dart';
import 'program_persegi.dart';
import 'program_lingkaran.dart';
import 'multipages_main.dart';
import 'gallery_main.dart';
import 'video_gallery_main.dart';
import 'pengenalhuruf_main.dart';
import 'pages_main.dart';
import 'formlogin_main.dart';
import 'quiz_main.dart';
import 'game_tap_main.dart';

void main() {
  runApp(const LandingApp());
}

// ...existing code...

class LandingApp extends StatelessWidget {
  const LandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landing Page - Tugas Mobile App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ...existing code...

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  late final List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
      });
    });

    _entries = [
      {
        'title': 'Persegi Panjang',
        'icon': Icons.rectangle_outlined,
        'color': Colors.blueAccent,
        'builder': () => PersegiPanjangApp(),
      },
      {
        'title': 'Persegi',
        'icon': Icons.square_outlined,
        'color': Colors.blueAccent,
        'builder': () => PersegiApp(),
      },
      {
        'title': 'Lingkaran',
        'icon': Icons.circle_outlined,
        'color': Colors.blueAccent,
        'builder': () => LingkaranApp(),
      },
      {
        'title': 'MULTIPAGES',
        'icon': Icons.multiple_stop_outlined,
        'color': const Color.fromARGB(255, 255, 68, 224),
        'builder': () => MultipagesApp(),
      },
      {
        'title': 'GALLERY APP & SPLASH SCREEN',
        'icon': Icons.image,
        'color': const Color.fromARGB(255, 255, 68, 74),
        'builder': () => GalleryApp(),
      },
      {
        'title': 'GALLERY VIDEO',
        'icon': Icons.video_library_outlined,
        'color': Colors.teal,
        'builder': () => VideoGalleryApp(),
      },
      {
        'title': 'PENGENAL HURUF',
        'icon': Icons.abc,
        'color': const Color.fromARGB(255, 132, 0, 150),
        'builder': () => PengenalHurufApp(),
      },
      {
        'title': 'WEBVIEW MULTI PAGE',
        'icon': Icons.web,
        'color': const Color.fromARGB(255, 117, 150, 0),
        'builder': () => WebViewApp(),
      },
      {
        'title': 'Form Login (Tanpa Database)',
        'icon': Icons.login,
        'color': const Color.fromARGB(255, 150, 122, 0),
        'builder': () => LoginApp(),
      },
      {
        'title': 'Quiz App (Tanpa Database)',
        'icon': Icons.quiz_sharp,
        'color': const Color.fromARGB(255, 93, 184, 146),
        'builder': () => QuizApp(),
      },
      {
        'title': 'Game Tap App (Dengan Leaderboard)',
        'icon': Icons.gamepad,
        'color': const Color.fromARGB(255, 101, 184, 93),
        'builder': () => GameTapApp(),
      },
      {
        'title': 'Proyek UAS - Berbagi File Lintas Platform',
        'icon': Icons.share,
        'color': const Color.fromARGB(255, 93, 125, 184),
        'builder': () => ProyekUasApp(),
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEntries {
    if (_query.isEmpty) return _entries;
    return _entries
        .where((e) => (e['title'] as String).toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Landing Page - Tugas Mobile App'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(Icons.home, size: 72, color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Landing Page - Tugas Mobile App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Landing page untuk Aplikasi Mobile',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),

                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari fitur...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 12.0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Grid of buttons
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 700
                      ? 3
                      : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                  children: List.generate(filtered.length, (index) {
                    final item = filtered[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => item['builder'](),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item['color'] as Color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: Text('Tidak ada hasil.')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
