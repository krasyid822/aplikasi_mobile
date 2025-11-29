import 'dart:async';
import 'dart:io';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'proyek_uas_unduh.dart';

class ProyekUasTerima extends StatefulWidget {
  const ProyekUasTerima({super.key});

  @override
  State<ProyekUasTerima> createState() => _ProyekUasTerimaState();
}

class _ProyekUasTerimaState extends State<ProyekUasTerima> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );
  String? _scanned;
  bool _isRunning = true;
  bool _cameraAvailable = true;
  String? _cameraError;
  List<Map<String, dynamic>> _discovered = [];
  bool _discovering = false;

  @override
  void initState() {
    super.initState();
    // try to start camera immediately and handle failures gracefully
    () async {
      try {
        await _controller.start();
        setState(() {
          _cameraAvailable = true;
          _cameraError = null;
        });
      } catch (e) {
        setState(() {
          _cameraAvailable = false;
          _cameraError = e.toString();
          _isRunning = false;
        });
      }
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _prettyBytes(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _scanned = code;
      _isRunning = false;
    });
    await _controller.stop();
    // if scanned value looks like an http url, start download page automatically
    final text = code.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      // navigate to download page
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ProyekUasUnduh(url: text)));
      }
    }
  }

  Future<void> _discoverOnLan({
    int port = 45678,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    setState(() {
      _discovering = true;
      _discovered = [];
    });

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // Build a list of broadcast targets: global 255.255.255.255 plus
      // per-interface /24 broadcasts (common case). We send multiple
      // times to improve delivery across different OS/network stacks.
      final message = 'MATKUL_DISCOVER';
      final targets = <InternetAddress>{InternetAddress('255.255.255.255')};
      try {
        final ifaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final ni in ifaces) {
          for (final addr in ni.addresses) {
            final a = addr.address;
            if (a.startsWith('169.254.') || a.startsWith('127.')) continue;
            final parts = a.split('.');
            if (parts.length == 4) {
              // assume /24 for broadcast (most home networks)
              final bcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                targets.add(InternetAddress(bcast));
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to list interfaces for broadcast targets: $e');
      }

      // Send broadcast multiple times with small pauses to increase chance
      // of delivery on platforms that drop single packets.
      for (var round = 0; round < 3; round++) {
        for (final t in targets) {
          try {
            socket.send(message.codeUnits, t, port);
          } catch (e) {
            debugPrint('Discovery send failed to ${t.address}: $e');
          }
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final results = <Map<String, dynamic>>[];

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram == null) return;
          final data = String.fromCharCodes(datagram.data).trim();
          if (data.isEmpty) return;
          try {
            final parsed = jsonDecode(data);
            if (parsed is Map) {
              results.add({
                'name':
                    parsed['name']?.toString() ??
                    parsed['url']?.toString() ??
                    data,
                'url': parsed['url']?.toString() ?? data,
                'size': parsed['size'] is int
                    ? parsed['size']
                    : (int.tryParse(parsed['size']?.toString() ?? '') ?? 0),
              });
            } else {
              // Not a map: fallback to raw string
              results.add({'name': data, 'url': data, 'size': 0});
            }
          } catch (_) {
            // Not JSON: treat as raw URL/text
            results.add({'name': data, 'url': data, 'size': 0});
          }
        }
      });

      // wait for timeout
      await Future.delayed(timeout);
      socket.close();

      setState(() {
        // dedupe by url
        final map = <String, Map<String, dynamic>>{};
        for (final r in results) {
          final url = r['url']?.toString() ?? '';
          if (url.isNotEmpty) map[url] = r;
        }
        _discovered = map.values.toList();
      });
    } catch (e) {
      debugPrint('Discovery error: $e');
      setState(() {
        _discovered = [];
      });
    } finally {
      setState(() {
        _discovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Kode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_cameraAvailable)
                    MobileScanner(controller: _controller, onDetect: _onDetect)
                  else
                    // placeholder when camera not available
                    Container(
                      color: Colors.black12,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off,
                              size: 64,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Kamera tidak tersedia',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (_cameraError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _cameraError!,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // instruction text above the frame
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        _scanned == null
                            ? 'Arahkan kamera ke QR/Barcode'
                            : 'Terdeteksi: $_scanned',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // semi-transparent scan area overlay
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color.fromARGB(153, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // When scanner is not running, show a centered large restart button
                  if (!_isRunning)
                    Center(
                      /* child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _scanned = null;
                            _isRunning = true;
                          });
                          try {
                            await _controller.start();
                            setState(() {
                              _cameraAvailable = true;
                              _cameraError = null;
                            });
                          } catch (e) {
                            setState(() {
                              _cameraAvailable = false;
                              _cameraError = e.toString();
                              _isRunning = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        label: const Text('Mulai Ulang Pindai', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                          backgroundColor: const Color(0xFF5B3EA3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ), */
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_cameraAvailable && _isRunning)
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Pindai aktif'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B3EA3),
                          ),
                        ),
                      if (!_cameraAvailable) ...[
                        ElevatedButton.icon(
                          onPressed: _discovering
                              ? null
                              : () => _discoverOnLan(),
                          icon: const Icon(Icons.wifi),
                          label: Text(
                            _discovering
                                ? 'Mencari...'
                                : 'Temukan di LAN${_discovered.isNotEmpty ? ' (${_discovered.length})' : ''}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _discovering
                              ? null
                              : () => _discoverOnLan(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Ulangi Broadcast'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF607D8B),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 12),
                      if (_scanned != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final url = _scanned!;
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProyekUasUnduh(url: url),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Lihat Unduh'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_discovered.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ditemukan pada LAN:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        for (final item in _discovered)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: OutlinedButton(
                              onPressed: () {
                                final url = item['url']?.toString() ?? '';
                                if (url.startsWith('http')) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProyekUasUnduh(url: url),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name']?.toString() ??
                                          item['url']?.toString() ??
                                          '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _prettyBytes(
                                      item['size'] is int
                                          ? item['size'] as int
                                          : int.tryParse(
                                                  item['size']?.toString() ??
                                                      '',
                                                ) ??
                                                0,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
