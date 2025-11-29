import 'package:flutter/material.dart';
import 'dart:math' show min;
import 'proyek_uas_kirim.dart';
import 'proyek_uas_terima.dart';

void main() {
  runApp(const ProyekUasApp());
}

class ProyekUasApp extends StatelessWidget {
  const ProyekUasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berbagi File',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121014),
        primaryColor: const Color(0xFF5B3EA3),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const DashboardPage(),
        '/show': (_) => const ProyekUasKirim(),
        '/scan': (_) => const ProyekUasTerima(),
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Berbagi File',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Make cards responsive: choose a comfortable max width
            final maxCardWidth = constraints.maxWidth > 600
                ? 280.0
                : constraints.maxWidth * 0.8;
            final isWide = constraints.maxWidth > 520;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Use Row when wide, Column when narrow
                        if (isWide)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DashboardCard(
                                width: maxCardWidth,
                                height: 260,
                                title: 'Kirim file',
                                subtitle: 'Tunjukkan Kode',
                                icon: Icons.qr_code,
                                colors: const [
                                  Color(0xFF5B3EA3),
                                  Color(0xFF4A2F7B),
                                ],
                                onTap: () =>
                                    Navigator.pushNamed(context, '/show'),
                              ),
                              const SizedBox(width: 20),
                              _DashboardCard(
                                width: maxCardWidth,
                                height: 260,
                                title: 'Terima file',
                                subtitle: 'Pindai Kode',
                                icon: Icons.qr_code_scanner,
                                colors: const [
                                  Color(0xFF5B5963),
                                  Color(0xFF474650),
                                ],
                                onTap: () =>
                                    Navigator.pushNamed(context, '/scan'),
                              ),
                            ],
                          )
                        else ...[
                          _DashboardCard(
                            width: maxCardWidth,
                            height: 200,
                            title: 'Kirim file',
                            subtitle: 'Tunjukkan Kode',
                            icon: Icons.qr_code,
                            colors: const [
                              Color(0xFF5B3EA3),
                              Color(0xFF4A2F7B),
                            ],
                            onTap: () => Navigator.pushNamed(context, '/show'),
                          ),
                          const SizedBox(height: 18),
                          _DashboardCard(
                            width: maxCardWidth,
                            height: 200,
                            title: 'Terima file',
                            subtitle: 'Pindai Kode',
                            icon: Icons.qr_code_scanner,
                            colors: const [
                              Color(0xFF5B5963),
                              Color(0xFF474650),
                            ],
                            onTap: () => Navigator.pushNamed(context, '/scan'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 160,
        height: height ?? 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // compute sizes based on available space to avoid overflow
            final availableW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : (width ?? 160);
            final availableH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (height ?? 160);
            final base = min(availableW, availableH);
            final iconBoxSize =
                base * 0.25; // a bit smaller to leave room for text
            final iconSize = iconBoxSize * 0.5;
            final titleFont = base > 200 ? 20.0 : 16.0;
            final subtitleFont = base > 200 ? 14.0 : 12.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: iconSize, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Flexible(
                  flex: 0,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleFont,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Scan page moved to `proyek_uas_terima.dart`
