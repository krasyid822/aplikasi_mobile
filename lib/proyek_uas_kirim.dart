import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProyekUasKirim extends StatefulWidget {
  const ProyekUasKirim({super.key});

  @override
  State<ProyekUasKirim> createState() => _ProyekUasKirimState();
}

class _ProyekUasKirimState extends State<ProyekUasKirim> {
  String? _fileName;
  int? _fileSize;
  HttpServer? _server;
  RawDatagramSocket? _discoverySocket;
  String? _hostIp;
  int? _port;
  String? _qrData;
  // track cached copy created by native picker so we can remove it later
  String? _cachedPath;
  bool _isCachedCopy = false;
  // qr data rendered by qr_flutter widget
  String _status = 'Menunggu pemilihan file...';
  bool _firewallOk = false;
  bool _udpLocalOk = false;
  bool _udpBroadcastOk = false;
  List<String> _candidateIps = [];

  @override
  void initState() {
    super.initState();
    // Start file picker after the first frame so dialog can show immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFile());
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _status = 'Membuka pemilih file...';
    });

    try {
      // Try native streaming picker first (Android) which copies to cache and returns a path
      String? path;
      try {
        const channel = MethodChannel('proyek_uas/filepicker');
        final res = await channel.invokeMethod<String?>(
          'openFileAndCopyToCache',
        );
        path = res;
      } on PlatformException {
        path = null;
      }

      // Fallback to file_selector if native picker not available or returned null
      XFile? picked;
      if (path == null) {
        picked = await openFile();
        if (picked == null) {
          setState(() {
            _status = 'Tidak ada file dipilih.';
          });
          return;
        }
        path = picked.path;
      }

      if (path.isEmpty) {
        setState(() {
          _status = 'File tidak tersedia.';
        });
        return;
      }

      final file = File(path);
      final stat = await file.stat();

      setState(() {
        _fileName =
            (picked?.name) ?? (path == null ? 'file' : path.split('/').last);
        _fileSize = stat.size;
        _status = 'File dipilih: $_fileName';
      });

      await _startServer(file);
    } catch (e) {
      setState(() {
        _status = 'Gagal memilih file: $e';
      });
    }
  }

  Future<void> _startServer(File file) async {
    await _stopServer();

    setState(() {
      _status = 'Memulai server sementara...';
    });

    try {
      // prefer a stable port so clients can reach predictably; fallback to random port
      const preferredPort = 8080;
      HttpServer? server;
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
      } catch (_) {
        server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }
      final serverBound = server;
      _server = serverBound;
      _port = serverBound.port;

      // collect candidate IPv4 addresses (private/non-linklocal)
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        type: InternetAddressType.IPv4,
      );
      final candidates = <String>[];
      for (final ni in interfaces) {
        for (final addr in ni.addresses) {
          final a = addr.address;
          if (addr.type != InternetAddressType.IPv4) continue;
          // skip obvious link-local addresses
          if (a.startsWith('169.254.')) continue;
          // skip IPv6 loopback etc
          candidates.add(a);
        }
      }

      // prefer private ranges (192.168.*, 10.*, 172.16-31.*)
      String? pick;
      for (final c in candidates) {
        if (c.startsWith('192.168.') ||
            c.startsWith('10.') ||
            RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(c)) {
          pick = c;
          break;
        }
      }
      // fallback to first candidate or loopback
      pick ??= candidates.isNotEmpty
          ? candidates.first
          : InternetAddress.loopbackIPv4.address;

      _candidateIps = candidates.isNotEmpty
          ? candidates
          : [InternetAddress.loopbackIPv4.address];
      _hostIp = pick;
      _qrData = 'http://$_hostIp:$_port/ezypizy';

      // QR widget will render _qrData

      setState(() {
        _status = 'Server berjalan di $_hostIp:$_port';
      });

      // Start listening
      serverBound.listen((HttpRequest req) async {
        try {
          if (req.method == 'GET' && req.uri.path == '/ezypizy') {
            req.response.headers.contentType = ContentType(
              'application',
              'octet-stream',
            );
            req.response.headers.add(
              'content-disposition',
              'attachment; filename="${_fileName ?? 'file'}"',
            );
            try {
              final length = await file.length();
              req.response.contentLength = length;
              // Stream the file to the response to avoid loading whole file into RAM
              await req.response.addStream(file.openRead());
            } finally {
              await req.response.close();
            }
          } else if (req.method == 'GET' && req.uri.path == '/info') {
            final info = {'name': _fileName, 'size': _fileSize, 'url': _qrData};
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode(info));
            await req.response.close();
          } else {
            req.response.statusCode = HttpStatus.notFound;
            await req.response.close();
          }
        } catch (e) {
          // ignore per-request errors
          try {
            req.response.statusCode = HttpStatus.internalServerError;
            await req.response.close();
          } catch (_) {}
        }
      });

      // start UDP listener for discovery requests on a fixed port
      try {
        _discoverySocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          45678,
        );
        _discoverySocket?.listen((event) {
          if (event == RawSocketEvent.read) {
            final datagram = _discoverySocket?.receive();
            if (datagram == null) return;
            final msg = String.fromCharCodes(datagram.data).trim();
            // respond to discovery requests
            if (msg == 'MATKUL_DISCOVER' && _qrData != null) {
              try {
                // reply with structured JSON so clients can show file info
                final info = {
                  'name': _fileName ?? 'file',
                  'url': _qrData,
                  'size': _fileSize ?? 0,
                };
                final resp = jsonEncode(info).codeUnits;
                _discoverySocket?.send(resp, datagram.address, datagram.port);
              } catch (_) {}
            }
          }
        });
      } catch (e) {
        // ignore discovery socket failures; discovery will simply not work
        debugPrint('Failed to bind discovery socket: $e');
      }

      // run a simple firewall check
      await _runFirewallCheck(_hostIp!, _port!);
    } catch (e) {
      setState(() {
        _status = 'Gagal memulai server: $e';
      });
    }
  }

  Future<void> _runFirewallCheck(String host, int port) async {
    setState(() {
      _status = 'Menjalankan pemeriksaan firewall...';
      _firewallOk = false;
    });

    // Attempt to connect to the server using loopback and the external IP
    var loopOk = false;
    var hostOk = false;

    try {
      final s = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 2),
      );
      s.destroy();
      loopOk = true;
    } catch (_) {
      loopOk = false;
    }

    try {
      final s = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      s.destroy();
      hostOk = true;
    } catch (_) {
      hostOk = false;
    }

    // UDP checks (performed outside setState)
    var udpLocal = false;
    var udpBroadcast = false;

    // 1) Local UDP loopback test
    try {
      final rs = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rp = rs.port;
      final completer = Completer<void>();
      rs.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = rs.receive();
          if (dg != null) udpLocal = true;
          completer.complete();
        }
      });
      rs.send([1, 2, 3, 4], InternetAddress.loopbackIPv4, rp);
      // wait briefly for loopback delivery
      await Future.any([
        completer.future,
        Future.delayed(const Duration(milliseconds: 300)),
      ]);
      rs.close();
    } catch (_) {
      udpLocal = false;
    }

    // 2) Try sending a UDP broadcast packet (can't guarantee delivery but can detect send errors)
    try {
      final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      s.broadcastEnabled = true;
      s.send([9, 9, 9], InternetAddress('255.255.255.255'), 45678);
      // if send didn't throw, consider broadcast send allowed locally
      udpBroadcast = true;
      s.close();
    } catch (_) {
      udpBroadcast = false;
    }

    // Update state with results
    setState(() {
      _firewallOk = hostOk;
      _udpLocalOk = udpLocal;
      _udpBroadcastOk = udpBroadcast;
      _status = loopOk
          ? (hostOk
                ? 'Terbuka untuk jaringan'
                : 'Terbuka secara lokal, tetapi mungkin diblokir oleh firewall jaringan')
          : 'Server tidak merespon meskipun loopback berhasil.';

      final udpSummary =
          ' UDP local: ${_udpLocalOk ? 'OK' : 'Blocked'}, broadcast send: ${_udpBroadcastOk ? 'OK' : 'Blocked'}';
      _status = '$_status.$udpSummary';
    });
  }

  Future<void> _stopServer() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _port = null;
    _hostIp = null;
    _qrData = null;
    try {
      _discoverySocket?.close();
    } catch (_) {}
    _discoverySocket = null;
  }

  String _prettyBytes(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunjukkan Kode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_qrData != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: _qrData ?? '',
                      size: 240,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black87,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black87,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),

                SelectableText(
                  _fileName ?? 'Belum ada file',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ukuran: ${_prettyBytes(_fileSize)}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 12),

                if (_qrData != null) ...[
                  // show candidate IPs selector to help LAN debugging
                  if (_candidateIps.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pilih alamat:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: _hostIp,
                          items: _candidateIps
                              .map(
                                (ip) => DropdownMenuItem(
                                  value: ip,
                                  child: Text(ip),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _hostIp = v;
                              _qrData = 'http://$_hostIp:$_port/ezypizy';
                            });
                          },
                        ),
                      ],
                    ),
                    /* const SizedBox(height: 8),
                    // Diagnostics dropdown
                    ExpansionTile(
                      title: const Text('Status Jaringan', style: TextStyle(color: Colors.white70)),
                      collapsedIconColor: Colors.white70,
                      iconColor: Colors.white70,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_firewallOk)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                  else
                                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  Text(_status, style: const TextStyle(color: Colors.white60)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(_udpLocalOk ? Icons.check_circle : Icons.signal_cellular_connected_no_internet_0_bar,
                                    color: _udpLocalOk ? Colors.green : Colors.orange, size: 16),
                                const SizedBox(width: 6),
                                const Text('UDP local', style: TextStyle(color: Colors.white60)),
                                const SizedBox(width: 16),
                                Icon(_udpBroadcastOk ? Icons.check_circle : Icons.wifi_off,
                                    color: _udpBroadcastOk ? Colors.green : Colors.orange, size: 16),
                                const SizedBox(width: 6),
                                const Text('UDP broadcast', style: TextStyle(color: Colors.white60)),
                              ])
                            ],
                          ),
                        )
                      ],
                    ), */
                  ],
                  const SizedBox(height: 8),
                  // Raw URL hidden from UI for cleaner presentation
                ],

                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    if (_firewallOk)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      )
                    else
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    // moved detailed diagnostics into an ExpansionTile below
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    /* ElevatedButton.icon(
                      onPressed: _qrData == null
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(text: _qrData!),
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('URL disalin ke clipboard'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('Salin URL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3EA3),
                      ),
                    ), */
                    /* OutlinedButton.icon(
                      onPressed: _file == null
                          ? null
                          : () async {
                              // Re-run firewall check
                              final messenger = ScaffoldMessenger.of(context);
                              if (_hostIp != null && _port != null) {
                                await _runFirewallCheck(_hostIp!, _port!);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pemeriksaan firewall selesai',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.security),
                      label: const Text('Periksa Firewall'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ), */
                    TextButton.icon(
                      onPressed: () async {
                        await _stopServer();
                        await _pickFile();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pilih Ulang File'),
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
