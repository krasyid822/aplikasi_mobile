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

  @override
  void initState() {
    super.initState();
    // ensure camera starts immediately
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  MobileScanner(controller: _controller, onDetect: _onDetect),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _scanned == null
                        ? 'Arahkan kamera ke QR/Barcode'
                        : 'Terdeteksi: $_scanned',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning
                            ? null
                            : () async {
                                setState(() {
                                  _scanned = null;
                                  _isRunning = true;
                                });
                                await _controller.start();
                              },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Mulai Ulang Pindai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B3EA3),
                        ),
                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
