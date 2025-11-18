import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _soundKey = 'tap_game_sound_enabled';
  static const String _durationKey = 'tap_game_duration_seconds';

  bool _soundEnabled = true;
  int _durationSeconds = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(_soundKey) ?? true;
      _durationSeconds = prefs.getInt(_durationKey) ?? 10;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
    await prefs.setInt(_durationKey, _durationSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _soundEnabled,
            title: const Text('Suara Tap'),
            subtitle: const Text('Aktif/nonaktifkan efek suara saat tap'),
            onChanged: (v) {
              setState(() => _soundEnabled = v);
              _save();
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Durasi Permainan (detik)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [10, 15, 20, 30].map((v) {
              final selected = _durationSeconds == v;
              return ChoiceChip(
                label: Text('$v'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _durationSeconds = v);
                  _save();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
