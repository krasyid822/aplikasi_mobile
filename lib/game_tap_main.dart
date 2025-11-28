import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Menu screen removed; game starts directly.
import 'game_tap_settings_screen.dart';

class GameTapApp extends StatefulWidget {
  const GameTapApp({super.key});

  @override
  State<GameTapApp> createState() => _GameTapAppState();
}

class _GameTapAppState extends State<GameTapApp>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  int timeLeft = 10;
  int score = 0;
  bool isPlaying = false;

  // Leaderboard per durasi (top 5 skor per durasi)
  static const String _leaderboardBaseKey = 'tap_game_leaderboard_';
  List<int> _topScores = <int>[]; // skor untuk durasi aktif

  // Settings
  static const String _soundKey = 'tap_game_sound_enabled';
  static const String _durationKey = 'tap_game_duration_seconds';
  bool _soundEnabled = true;
  int _durationSeconds = 10;

  // Animation controller and animation for score "pop"
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  // Audio player for tap SFX
  late final AudioPlayer _tapPlayer;
  final AssetSource _tapSound = AssetSource(
    'audio/tap_game/confirm-tap-394001.ogg',
  );

  @override
  void initState() {
    super.initState();
    _tapPlayer = AudioPlayer();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_animController);
    // Optional: reverse back to normal automatically
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.reverse();
      }
    });
    _loadSettings(); // _loadSettings akan memanggil load leaderboard sesuai durasi
  }

  void startGame() {
    setState(() {
      timeLeft = _durationSeconds;
      score = 0;
      isPlaying = true;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          isPlaying = false;
          t.cancel();
        }
      });
      if (!isPlaying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onGameEnd();
        });
      }
    });
  }

  void addScore() {
    if (isPlaying) {
      setState(() {
        score++;
      });
      // Trigger pop animation
      _animController.forward(from: 0);
      // Play tap sound effect (restart if already playing)
      // Fire-and-forget; no need to await
      if (_soundEnabled) {
        _tapPlayer.stop();
        _tapPlayer.play(_tapSound);
      }
    }
  }

  @override
  void dispose() {
    if (mounted) {
      try {
        if (timer?.isActive ?? false) timer?.cancel();
      } catch (_) {}
    }
    _tapPlayer.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Leaderboard helpers (per durasi)
  String _keyForDuration(int d) => '$_leaderboardBaseKey$d';

  Future<List<int>> _loadLeaderboardFor(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForDuration(duration));
    if (raw == null || raw.isEmpty) return <int>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list.whereType<int>().toList()
        ..sort((b, a) => a.compareTo(b));
      return parsed.take(5).toList();
    } catch (_) {
      return <int>[];
    }
  }

  Future<void> _loadCurrentLeaderboard() async {
    final scores = await _loadLeaderboardFor(_durationSeconds);
    setState(() => _topScores = scores);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(_soundKey) ?? true;
      _durationSeconds = prefs.getInt(_durationKey) ?? 10;
    });
    await _loadCurrentLeaderboard();
  }

  Future<void> _saveCurrentLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyForDuration(_durationSeconds),
      jsonEncode(_topScores),
    );
  }

  void _recordScore(int value) {
    if (value <= 0) return;
    _topScores.add(value);
    _topScores.sort((b, a) => a.compareTo(b));
    if (_topScores.length > 5) {
      _topScores = _topScores.sublist(0, 5);
    }
    _saveCurrentLeaderboard();
    setState(() {});
  }

  void _onGameEnd() {
    _recordScore(score);
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Waktu Habis'),
          content: Text('Skor kamu: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showLeaderboardSheet();
              },
              child: const Text('Lihat Leaderboard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaderboardSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        int selectedDuration = _durationSeconds;
        final durations = [10, 15, 20, 30];
        final Map<int, List<int>> cache = {};
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<List<int>> currentScoresFuture;
            if (cache.containsKey(selectedDuration)) {
              currentScoresFuture = Future.value(cache[selectedDuration]!);
            } else {
              currentScoresFuture = _loadLeaderboardFor(selectedDuration).then((
                scores,
              ) {
                cache[selectedDuration] = scores;
                return scores;
              });
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Leaderboard (Top 5 per Durasi)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: durations.map((d) {
                        final selected = d == selectedDuration;
                        return ChoiceChip(
                          label: Text('${d}s'),
                          selected: selected,
                          onSelected: (_) {
                            selectedDuration = d;
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<int>>(
                      future: currentScoresFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final data = snap.data ?? <int>[];
                        if (data.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Belum ada skor untuk durasi ini.'),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: data.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = data[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text('Skor: $s'),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            cache.remove(selectedDuration);
                            await _clearLeaderboard();
                            setModalState(() {});
                          },
                          child: const Text('Reset (Durasi Aktif)'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            startGame();
                          },
                          child: const Text('Main Lagi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearLeaderboard() async {
    _topScores.clear();
    await _saveCurrentLeaderboard();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: GestureDetector(
        onTap: addScore,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Waktu: $timeLeft',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best: ${_topScores.isNotEmpty ? _topScores.first : 0}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              // Use ScaleTransition to animate the score when tapped
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  'Skor: $score',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (!isPlaying)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: startGame,
                      child: const Text('Mulai Game'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _showLeaderboardSheet,
                      child: const Text('Leaderboard'),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Pengaturan',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                        await _loadSettings(); // refresh durasi & leaderboard
                      },
                      icon: const Icon(Icons.settings),
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

void main() => runApp(const TapGameApp());

class TapGameApp extends StatelessWidget {
  const TapGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tap Game',
      home: const GameTapApp(),
    );
  }
}
