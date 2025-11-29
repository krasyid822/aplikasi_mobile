import 'package:flutter/material.dart';
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
                  child: Column(
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
                          colors: const [Color(0xFF5B3EA3), Color(0xFF4A2F7B)],
                          onTap: () => Navigator.pushNamed(context, '/show'),
                        ),
                        const SizedBox(height: 18),
                        _DashboardCard(
                          width: maxCardWidth,
                          height: 200,
                          title: 'Terima file',
                          subtitle: 'Pindai Kode',
                          icon: Icons.qr_code_scanner,
                          colors: const [Color(0xFF5B5963), Color(0xFF474650)],
                          onTap: () => Navigator.pushNamed(context, '/scan'),
                        ),
                      ],
                    ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: (width ?? 160) * 0.35,
              height: (width ?? 160) * 0.35,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: ((width ?? 160) * 0.35) * 0.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (width ?? 160) > 200 ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: (width ?? 160) > 200 ? 14 : 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Scan page moved to `proyek_uas_terima.dart`
