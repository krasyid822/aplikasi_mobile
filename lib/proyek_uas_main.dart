import 'package:flutter/material.dart';
import 'dart:math' show min;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _lanIp = '-';
  String _ssid = '-';
  String _ssidLabel = 'SSID';
  Map<String, String> _addrToInterface = {};
  final List<String> _candidates = [];
  String? _selectedIp;

  @override
  void initState() {
    super.initState();
    _fetchNetworkInfo();
  }

  Future<void> _fetchNetworkInfo() async {
    String lan = '-';
    String ssid = '-';

    final Map<String, String> addrToInterface = {};
    final candidates = <String>[];
    String? pick;

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        type: InternetAddressType.IPv4,
      );
      for (final ni in interfaces) {
        for (final addr in ni.addresses) {
          final a = addr.address;
          if (addr.type != InternetAddressType.IPv4) continue;
          if (a.startsWith('169.254.')) continue;
          candidates.add(a);
          addrToInterface[a] = ni.name;
        }
      }

      for (final c in candidates) {
        if (c.startsWith('192.168.') ||
            c.startsWith('10.') ||
            RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(c)) {
          pick = c;
          break;
        }
      }

      pick ??= candidates.isNotEmpty
          ? candidates.first
          : InternetAddress.loopbackIPv4.address;
      lan = pick;
    } catch (_) {
      // ignore errors enumerating interfaces
    }

    try {
      if (Platform.isWindows) {
        _ssidLabel = 'Interface';
        ssid = addrToInterface[pick] ?? '-';
      } else if (Platform.isAndroid) {
        final status = await Permission.location.status;
        if (!status.isGranted) {
          final result = await Permission.location.request();
          if (!result.isGranted) {
            ssid = '<permission required>';
          } else {
            final Map? info = await MethodChannel(
              'proyek_uas/network',
            ).invokeMapMethod('getWifiInfo');
            if (info != null) {
              if (info['ssid'] != null) ssid = info['ssid'] as String;
              if (info['ip'] != null) {
                final returnedIp = info['ip'] as String;
                if (addrToInterface.containsKey(returnedIp)) pick = returnedIp;
                if (lan == '-' || lan == InternetAddress.loopbackIPv4.address) {
                  lan = returnedIp;
                }
              }
              if (info['ssid'] != null) {
                final returnedSsid = (info['ssid'] as String).toLowerCase();
                for (final entry in addrToInterface.entries) {
                  final name = entry.value.toLowerCase();
                  if (name == returnedSsid || name.contains(returnedSsid)) {
                    pick = entry.key;
                    break;
                  }
                }
              }
            }
          }
        } else {
          final Map? info = await MethodChannel(
            'proyek_uas/network',
          ).invokeMapMethod('getWifiInfo');
          if (info != null) {
            if (info['ssid'] != null) ssid = info['ssid'] as String;
            if (info['ip'] != null) {
              final returnedIp = info['ip'] as String;
              if (addrToInterface.containsKey(returnedIp)) pick = returnedIp;
              if (lan == '-' || lan == InternetAddress.loopbackIPv4.address) {
                lan = returnedIp;
              }
            }
            if (info['ssid'] != null) {
              final returnedSsid = (info['ssid'] as String).toLowerCase();
              for (final entry in addrToInterface.entries) {
                final name = entry.value.toLowerCase();
                if (name == returnedSsid || name.contains(returnedSsid)) {
                  pick = entry.key;
                  break;
                }
              }
            }
          }

          // If SSID wasn't returned or is a placeholder (e.g. permission message
          // or '<unknown ssid>'), fall back to showing the interface name.
          final unknown =
              ssid.trim().isEmpty ||
              ssid.startsWith('<') ||
              ssid.toLowerCase().contains('unknown');
          if (unknown) {
            _ssidLabel = 'Interface';
            ssid = addrToInterface[pick] ?? ssid;
          }
        }
      } else {
        try {
          final Map? info = await MethodChannel(
            'proyek_uas/network',
          ).invokeMapMethod('getWifiInfo');
          if (info != null) {
            if (info['ssid'] != null) ssid = info['ssid'] as String;
            if (info['ip'] != null) {
              final returnedIp = info['ip'] as String;
              if (addrToInterface.containsKey(returnedIp)) pick = returnedIp;
              if (lan == '-' || lan == InternetAddress.loopbackIPv4.address) {
                lan = returnedIp;
              }
            }
            if (info['ssid'] != null) {
              final returnedSsid = (info['ssid'] as String).toLowerCase();
              for (final entry in addrToInterface.entries) {
                final name = entry.value.toLowerCase();
                if (name == returnedSsid || name.contains(returnedSsid)) {
                  pick = entry.key;
                  break;
                }
              }
            }
          } else {
            _ssidLabel = 'Interface';
            ssid = addrToInterface[pick] ?? '-';
          }
        } catch (_) {
          _ssidLabel = 'Interface';
          ssid = addrToInterface[pick] ?? '-';
        }
      }
    } catch (_) {
      // ignore - permission or platform channel errors
    }

    if (!mounted) return;
    setState(() {
      _addrToInterface = addrToInterface;
      _candidates.clear();
      _candidates.addAll(candidates);
      _selectedIp = pick;
      _lanIp = lan;
      _ssid = ssid;
    });
  }

  Future<void> _showInterfacePicker() async {
    if (_candidates.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Text(
                  'Lihat Interface',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              ..._candidates.map((ip) {
                final name = _addrToInterface[ip] ?? '-';
                return ListTile(
                  title: Text(ip),
                  subtitle: Text(name),
                  trailing: ip == _selectedIp ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(ctx).pop(ip),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedIp = chosen;
        _lanIp = chosen;
        if (_ssidLabel == 'Interface') {
          _ssid = _addrToInterface[chosen] ?? _ssid;
        }
      });
    }
  }

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
                  // ensure minHeight is non-negative to avoid runtime layout errors
                  minHeight: constraints.maxHeight.isFinite
                      ? (constraints.maxHeight > 48
                            ? constraints.maxHeight - 48
                            : 0.0)
                      : 0.0,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Network info above the first card: compact two-line block
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.wifi,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LAN: $_lanIp',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: _showInterfacePicker,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.router,
                                      size: 16,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxCardWidth * 0.9,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$_ssidLabel: $_ssid',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.white60,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

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
