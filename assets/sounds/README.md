# Emergency Alert Sound

This directory should contain the emergency alert sound file.

## Required File:
- `emergency_alert.mp3` - Emergency siren/alarm sound

## Where to Get Emergency Sounds:

### Free Resources:
1. **Freesound.org**: https://freesound.org/
   - Search for: "emergency siren", "ambulance siren", "alert sound"
   
2. **Zapsplat**: https://www.zapsplat.com/
   - Free sound effects with attribution
   
3. **Mixkit**: https://mixkit.co/free-sound-effects/
   - Free emergency sound effects

### Recommended Characteristics:
- **Duration**: 2-3 seconds
- **Format**: MP3
- **Volume**: Loud and clear
- **Type**: Emergency siren, alarm, or urgent beep pattern

## Fallback:
If this file is not present, the app will use system alert sounds as a fallback.

## How to Add:
1. Download or create an emergency alert sound
2. Name it: `emergency_alert.mp3`
3. Place it in this directory: `assets/sounds/`
4. The app will automatically use it

## Testing:
After adding the sound file:
```bash
flutter pub get
flutter run
```

The sound will play when a new emergency request arrives in the Driver Dashboard.
