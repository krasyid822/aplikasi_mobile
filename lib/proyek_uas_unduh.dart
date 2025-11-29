import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ProyekUasUnduh extends StatefulWidget {
  final String url;
  const ProyekUasUnduh({super.key, required this.url});

  @override
  State<ProyekUasUnduh> createState() => _ProyekUasUnduhState();
}

class _ProyekUasUnduhState extends State<ProyekUasUnduh> {
  int? _totalBytes;
  int _received = 0;
  double _speed = 0; // bytes per second
  String _status = 'Menunggu...';
  StreamSubscription<List<int>>? _sub;
  File? _outFile;
  bool _completed = false;
  Stopwatch? _stopwatch;

  @override
  void initState() {
    super.initState();
    // Start download immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDownload());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<Directory> _downloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Public Download folder on Android
        final d = Directory('/storage/emulated/0/Download');
        if (await d.exists()) return d;
        // fallback to app external directory
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      }
      // Desktop and iOS: use path_provider
      final maybe = await getDownloadsDirectory();
      if (maybe != null) return maybe;
    } catch (_) {}
    // fallback to temporary directory
    return await getTemporaryDirectory();
  }

  String _prettyBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _etaText() {
    if (_totalBytes == null || _speed <= 0) return '-';
    final remaining = _totalBytes! - _received;
    final sec = (remaining / _speed).ceil();
    final minutes = sec ~/ 60;
    final seconds = sec % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _startDownload() async {
    setState(() {
      _status = 'Mempersiapkan unduhan...';
      _received = 0;
      _totalBytes = null;
      _speed = 0;
      _completed = false;
    });

    final uri = Uri.parse(widget.url);
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        setState(() {
          _status = 'HTTP ${response.statusCode}';
        });
        return;
      }

      final contentLength = response.contentLength; // -1 if unknown
      _totalBytes = contentLength > 0 ? contentLength : null;

      // determine filename
      String filename = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'download.bin';
      final disposition = response.headers.value('content-disposition');
      if (disposition != null) {
        // try to extract filename="..."
        final m = RegExp(
          r'filename\s*=\s*"?([^";]+)"?',
        ).firstMatch(disposition);
        if (m != null) filename = m.group(1)!;
      }

      final downloadsDir = await _downloadsDirectory();
      final outPath = '${downloadsDir.path}${Platform.pathSeparator}$filename';
      final outFile = File(outPath);
      final sink = outFile.openWrite();
      _outFile = outFile;

      _stopwatch = Stopwatch()..start();
      var lastReceived = 0;
      var lastTime = DateTime.now();

      setState(() {
        _status = 'Mengunduh ke ${outFile.path}';
      });

      // Listen chunked
      _sub = response.listen(
        (chunk) {
          sink.add(chunk);
          _received += chunk.length;

          final now = DateTime.now();
          final dt = now.difference(lastTime).inMilliseconds;
          if (dt >= 500) {
            final deltaBytes = _received - lastReceived;
            _speed = deltaBytes / (dt / 1000);
            lastReceived = _received;
            lastTime = now;
          }

          setState(() {});
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          _stopwatch?.stop();
          setState(() {
            _completed = true;
            _status = 'Selesai: ${outFile.path}';
            _speed = 0;
          });
        },
        onError: (e) async {
          try {
            await sink.close();
          } catch (_) {}
          setState(() {
            _status = 'Gagal: $e';
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _status = 'Gagal memulai unduhan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_totalBytes != null && _totalBytes! > 0)
        ? (_received / _totalBytes!)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduh File'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.url, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              if (percent != null)
                LinearProgressIndicator(value: percent)
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _totalBytes != null
                        ? '${_prettyBytes(_received)} / ${_prettyBytes(_totalBytes!)}'
                        : _prettyBytes(_received),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _completed
                        ? 'Selesai'
                        : (_speed > 0
                              ? '${(_speed / 1024).toStringAsFixed(1)} KB/s'
                              : '-'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ETA: ${_etaText()}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  Text(_status, style: const TextStyle(color: Colors.white60)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _completed
                        ? () {
                            // open file location - best-effort: not using external package
                            final path = _outFile?.path ?? '-';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('File disimpan: $path')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Buka Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3EA3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // cancel download and leave
                      final navigator = Navigator.of(context);
                      await _sub?.cancel();
                      if (!mounted) return;
                      navigator.pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Batal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
