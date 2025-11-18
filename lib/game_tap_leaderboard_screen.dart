import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const String _leaderboardKey = 'tap_game_leaderboard';
  List<int> _scores = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_leaderboardKey);
    if (raw == null || raw.isEmpty) {
      setState(() => _scores = []);
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list.whereType<int>().toList()
        ..sort((b, a) => a.compareTo(b));
      setState(() => _scores = parsed);
    } catch (_) {
      setState(() => _scores = []);
    }
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_leaderboardKey, jsonEncode(<int>[]));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: _scores.isEmpty
          ? const Center(child: Text('Belum ada skor.'))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _scores.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _scores[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text('Skor: $s'),
                );
              },
            ),
    );
  }
}
