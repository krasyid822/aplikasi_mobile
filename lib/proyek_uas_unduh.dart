import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _completed = false;
  String? _savedPath;
  bool _deleted = false;
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

  Future<void> _openDownloadsFolder() async {
    try {
      final dir = await _downloadsDirectory();
      if (Platform.isWindows) {
        await Process.run('explorer', [dir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dir.path]);
      } else if (Platform.isAndroid) {
        // Use platform channel to open the system Downloads UI to avoid FileUriExposedException
        try {
          await MethodChannel(
            'proyek_uas/open_folder',
          ).invokeMethod('openDownloadsFolderAndroid');
        } catch (e) {
          throw 'Gagal membuka Downloads: $e';
        }
      } else if (Platform.isIOS) {
        final uri = Uri.file(dir.path);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Tidak dapat membuka $uri';
        }
      } else {
        throw 'Platform tidak didukung';
      }
    } catch (e) {
      if (!mounted) return;
      final msg = SnackBar(content: Text('Gagal membuka folder: $e'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(msg);
      });
    }
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
            _savedPath = outFile.path;
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
    double? percent;
    if (_totalBytes != null && _totalBytes! > 0) {
      percent = _received / _totalBytes!;
      if (percent > 1.0) percent = 1.0;
    } else {
      percent = null;
    }
    if (_completed) percent = 1.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduh File'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // allow long URLs to wrap and avoid overflow
                SelectableText(
                  widget.url,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                if (percent != null)
                  LinearProgressIndicator(value: percent)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: _totalBytes != null
                            ? '${_prettyBytes(_received)} / ${_prettyBytes(_totalBytes!)}'
                            : _prettyBytes(_received),
                        child: Text(
                          _totalBytes != null
                              ? '${_prettyBytes(_received)} / ${_prettyBytes(_totalBytes!)}'
                              : _prettyBytes(_received),
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: Tooltip(
                        message: _completed
                            ? 'Selesai'
                            : (_speed > 0
                                  ? '${(_speed / 1024).toStringAsFixed(1)} KB/s'
                                  : '-'),
                        child: Text(
                          _completed
                              ? 'Selesai'
                              : (_speed > 0
                                    ? '${(_speed / 1024).toStringAsFixed(1)} KB/s'
                                    : '-'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: 'ETA: ${_etaText()}',
                        child: Text(
                          'ETA: ${_etaText()}',
                          style: const TextStyle(color: Colors.white60),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Tooltip(
                        message: _status,
                        child: Text(
                          _status,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white60),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_deleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'File telah dihapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                // Wrap to avoid horizontal overflow on small screens
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (_completed && !_deleted)
                          ? () => _openDownloadsFolder()
                          : null,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Buka Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3EA3),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!_completed) {
                          // cancel download and leave
                          await _sub?.cancel();
                          if (!mounted) return;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(context).pop();
                          });
                          return;
                        }

                        // Completed -> act as delete
                        if (_savedPath != null) {
                          try {
                            final f = File(_savedPath!);
                            if (await f.exists()) await f.delete();
                            if (!mounted) return;
                            setState(() {
                              _deleted = true;
                              _savedPath = null;
                              _status = 'File dihapus';
                            });
                            final msg = const SnackBar(
                              content: Text('File dihapus'),
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(msg);
                            });
                          } catch (e) {
                            if (!mounted) return;
                            final msg = SnackBar(
                              content: Text('Gagal menghapus file: $e'),
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(msg);
                            });
                          }
                        } else {
                          if (!mounted) return;
                          final msg = const SnackBar(
                            content: Text('Tidak ada file untuk dihapus'),
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(msg);
                          });
                        }
                      },
                      icon: Icon(_completed ? Icons.delete : Icons.close),
                      label: Text(_completed ? 'Hapus' : 'Batal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
