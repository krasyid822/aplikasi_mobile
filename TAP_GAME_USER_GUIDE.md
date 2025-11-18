# Tap Game - User Guide

## Overview
The Tap Game is a simple reaction-time game where you tap the screen as fast as possible within a time limit. The game now features optimized audio with minimal delay on Android devices.

## How to Play

1. **Start the Game**
   - Tap the "Mulai Game" button on the main screen
   - The timer will start counting down from your selected duration

2. **Gameplay**
   - Tap anywhere on the screen as fast as you can
   - Each tap increases your score by 1
   - A "pop" animation shows your current score
   - You'll hear an immediate audio feedback (if enabled)

3. **Game End**
   - When time runs out, your final score is displayed
   - Your score is automatically saved to the leaderboard
   - Choose to view the leaderboard or close the dialog

## Features

### ⚙️ Settings
Access settings by tapping the gear icon:

- **Suara Efek** (Sound Effects)
  - Toggle sound on/off
  - Audio uses optimized low-latency playback

- **Durasi Permainan** (Game Duration)
  - Choose from: 10, 15, 20, or 30 seconds
  - Each duration has its own leaderboard

### 🏆 Leaderboard
- View top 5 scores for each duration
- Switch between durations using the chips
- Each duration maintains separate scores
- Reset option to clear current duration's scores

### 🎵 Audio Features
- **Low Latency**: Optimized for Android with minimal delay
- **Sound Stacking**: Multiple taps create overlapping sounds
- **Pre-loaded**: Audio ready before gameplay starts
- **Instant Feedback**: Tap response < 50ms on most devices

## Tips for High Scores

1. **Find Your Rhythm**
   - Try different tapping patterns
   - Some players prefer rapid single-finger taps
   - Others use alternating fingers

2. **Stay Focused**
   - Watch the timer to pace yourself
   - Don't panic when time is low

3. **Practice Different Durations**
   - Shorter durations test pure speed
   - Longer durations test endurance

4. **Use Sound Feedback**
   - Audio helps maintain rhythm
   - Instant feedback confirms each tap

## Troubleshooting

### Audio Issues

**No Sound on Tap**
- Check that "Suara Efek" is enabled in settings
- Verify device volume is not muted
- Ensure audio file exists in assets folder

**Audio Delay**
- Should be < 50ms on most devices
- Some older devices may have inherent audio lag
- Try closing other apps that use audio

**Audio Not Stacking**
- This is normal - up to 5 simultaneous sounds supported
- Very rapid tapping may reach the limit

### Performance Issues

**Slow Animation**
- Close background apps
- Restart the game
- Try a shorter duration to reduce processing

**Tap Not Registering**
- Ensure you're tapping within game boundaries
- Check if game is still running (timer > 0)

## Technical Specifications

### Audio System
- **Latency**: ~10-30ms typical, up to 50ms on older devices
- **Sample Rate**: 22050 Hz or 44100 Hz
- **Format**: MP3
- **Players**: 5 simultaneous audio channels

### Game Mechanics
- **Tap Detection**: Full screen gesture detector
- **Timer**: 1-second interval updates
- **Score**: Increments immediately on tap
- **Animation**: 150ms scale transition

### Data Storage
- **Leaderboard**: Stored locally via SharedPreferences
- **Settings**: Persisted between sessions
- **Privacy**: No data sent to external servers

## Future Enhancements (Planned)

- [ ] Combo system for consecutive taps
- [ ] Visual effects on tap location
- [ ] Daily challenges
- [ ] Achievement system
- [ ] Global online leaderboard
- [ ] Haptic feedback option
- [ ] Multiple sound themes

## Credits

**Game Design**: Tap game with leaderboard system
**Audio Optimization**: Low-latency Android implementation
**Framework**: Flutter

## Support

For issues or suggestions, please contact the developer or open an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: November 2024  
**Tested On**: Android devices with API 21+
