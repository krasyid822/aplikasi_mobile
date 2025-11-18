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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(_soundKey) ?? true;
      _durationSeconds = prefs.getInt(_durationKey) ?? 10;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
    await prefs.setInt(_durationKey, _durationSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Suara Efek'),
            subtitle: const Text('Aktifkan suara saat tap'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSettings();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Durasi Permainan'),
            subtitle: Text('$_durationSeconds detik'),
          ),
          ...([10, 15, 20, 30].map((duration) {
            return RadioListTile<int>(
              title: Text('$duration detik'),
              value: duration,
              groupValue: _durationSeconds,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _durationSeconds = value);
                  _saveSettings();
                }
              },
            );
          })),
        ],
      ),
    );
  }
}
