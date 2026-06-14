import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling emergency alert sounds and notifications
class EmergencyAlertService {
  static final EmergencyAlertService _instance =
      EmergencyAlertService._internal();
  factory EmergencyAlertService() => _instance;
  EmergencyAlertService._internal();

  AudioPlayer? _audioPlayer;
  StreamSubscription? _playerCompleteSubscription;
  Timer? _vibrationTimer;
  bool _isPlaying = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _repeatCount = 0;
  static const int _maxRepeats = 10; // Repeat 10 times (about 30 seconds)

  /// Initialize the service and load settings
  Future<void> initialize() async {
    await _loadSettings();
    await _initAudioPlayer();
  }

  /// Initialize or reset the audio player
  Future<void> _initAudioPlayer() async {
    // Dispose old player if exists
    await _playerCompleteSubscription?.cancel();
    await _audioPlayer?.dispose();
    
    // Create fresh audio player
    _audioPlayer = AudioPlayer();
    await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer!.setVolume(1.0); // Maximum volume
    
    try {
      // Set audio context for maximum priority
      await _audioPlayer!.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );
      print('[EmergencyAlert] ✅ Audio player initialized with alarm settings');
    } catch (e) {
      print('[EmergencyAlert] ⚠️ Error setting audio context: $e');
    }
  }

  /// Load user preferences for sound and vibration
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('emergency_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('emergency_vibration_enabled') ?? true;
    } catch (e) {
      print('[EmergencyAlert] Error loading settings: $e');
    }
  }

  /// Save sound enabled setting
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emergency_sound_enabled', enabled);
    } catch (e) {
      print('[EmergencyAlert] Error saving sound setting: $e');
    }
  }

  /// Save vibration enabled setting
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emergency_vibration_enabled', enabled);
    } catch (e) {
      print('[EmergencyAlert] Error saving vibration setting: $e');
    }
  }

  /// Play emergency alert sound with vibration
  Future<void> playEmergencyAlert() async {
    print('[EmergencyAlert] ⚠️ playEmergencyAlert() called');
    print('[EmergencyAlert] Sound enabled: $_soundEnabled, Vibration enabled: $_vibrationEnabled');
    
    if (_isPlaying) {
      print('[EmergencyAlert] Alert already playing, stopping first...');
      await stopAlert();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Reinitialize audio player for fresh state
    await _initAudioPlayer();
    
    _isPlaying = true;
    _repeatCount = 0;

    print('[EmergencyAlert] 🚨 Starting emergency alert');

    // Play vibration if enabled
    if (_vibrationEnabled) {
      print('[EmergencyAlert] Starting vibration...');
      await _startVibration();
    } else {
      print('[EmergencyAlert] Vibration disabled by user');
    }

    // Play sound if enabled
    if (_soundEnabled) {
      print('[EmergencyAlert] Starting alert sound...');
      await _playAlertSound();
    } else {
      print('[EmergencyAlert] Sound disabled by user');
    }
    
    print('[EmergencyAlert] ✅ Emergency alert started successfully');
  }

  /// Play the alert sound and repeat
  Future<void> _playAlertSound() async {
    if (_audioPlayer == null) {
      print('[EmergencyAlert] Audio player not initialized');
      return;
    }
    
    try {
      // Cancel any existing subscription
      await _playerCompleteSubscription?.cancel();
      
      // Set up the completion listener BEFORE playing
      _playerCompleteSubscription = _audioPlayer!.onPlayerComplete.listen((_) async {
        if (_isPlaying && _repeatCount < _maxRepeats) {
          _repeatCount++;
          print('[EmergencyAlert] Repeating alert (${_repeatCount}/$_maxRepeats)');
          await Future.delayed(const Duration(milliseconds: 500));
          if (_isPlaying && _audioPlayer != null) {
            try {
              await _audioPlayer!.play(AssetSource('sounds/emergency_alert.mp3'));
            } catch (e) {
              print('[EmergencyAlert] Error repeating sound: $e');
            }
          }
        } else if (_isPlaying) {
          await stopAlert();
        }
      });
      
      // Try to play from assets
      try {
        print('[EmergencyAlert] 🎵 Attempting to play: sounds/emergency_alert.mp3');
        await _audioPlayer!.play(
          AssetSource('sounds/emergency_alert.mp3'),
          volume: 1.0,
        );
        print('[EmergencyAlert] ✅ Alert sound started playing');
      } catch (e) {
        // If asset not found, use system sound
        print('[EmergencyAlert] ⚠️ Asset not found, trying system sound: $e');
        
        // Try alternative asset
        try {
          await _audioPlayer!.play(
            AssetSource('sounds/emergency-alarm-with-reverb-29431.mp3'),
            volume: 1.0,
          );
          print('[EmergencyAlert] ✅ Playing alternative alert sound');
        } catch (e2) {
          print('[EmergencyAlert] ❌ Alternative asset also failed: $e2');
          await SystemSound.play(SystemSoundType.alert);
          
          // Fallback: repeat system sound
          await _repeatSystemSound();
          return;
        }
      }
    } catch (e) {
      print('[EmergencyAlert] Error playing sound: $e');
    }
  }

  /// Repeat system sound as fallback
  Future<void> _repeatSystemSound() async {
    while (_isPlaying && _repeatCount < _maxRepeats) {
      await SystemSound.play(SystemSoundType.alert);
      _repeatCount++;
      await Future.delayed(const Duration(seconds: 2));
    }
    await stopAlert();
  }

  /// Start vibration pattern
  Future<void> _startVibration() async {
    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        print('[EmergencyAlert] 📳 Starting continuous vibration...');
        
        // Initial vibration
        await Vibration.vibrate(duration: 1000, amplitude: 255);
        
        // Set up timer for continuous vibration
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
          if (_isPlaying && _vibrationEnabled) {
            try {
              await Vibration.vibrate(duration: 1000, amplitude: 255);
            } catch (e) {
              print('[EmergencyAlert] Vibration error in timer: $e');
            }
          } else {
            timer.cancel();
          }
        });
        
        print('[EmergencyAlert] ✅ Vibration started successfully');
      } else {
        print('[EmergencyAlert] ⚠️ Device does not support vibration');
      }
    } catch (e) {
      print('[EmergencyAlert] ❌ Error starting vibration: $e');
    }
  }

  /// Stop emergency alert
  Future<void> stopAlert() async {
    print('[EmergencyAlert] 🛑 Stopping emergency alert');
    _isPlaying = false;
    _repeatCount = 0;

    // Cancel vibration timer
    try {
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      print('[EmergencyAlert] Vibration timer cancelled');
    } catch (e) {
      print('[EmergencyAlert] Error canceling vibration timer: $e');
    }

    try {
      await _playerCompleteSubscription?.cancel();
      _playerCompleteSubscription = null;
      print('[EmergencyAlert] Audio subscription cancelled');
    } catch (e) {
      print('[EmergencyAlert] Error canceling subscription: $e');
    }

    try {
      await _audioPlayer?.stop();
      print('[EmergencyAlert] Audio stopped');
    } catch (e) {
      print('[EmergencyAlert] Error stopping audio: $e');
    }

    try {
      await Vibration.cancel();
      print('[EmergencyAlert] Vibration cancelled');
    } catch (e) {
      print('[EmergencyAlert] Error stopping vibration: $e');
    }
    
    print('[EmergencyAlert] ✅ Alert stopped successfully');
  }

  /// Check if alert is currently playing
  bool get isPlaying => _isPlaying;

  /// Get sound enabled status
  bool get isSoundEnabled => _soundEnabled;

  /// Get vibration enabled status
  bool get isVibrationEnabled => _vibrationEnabled;

  /// Dispose resources
  Future<void> dispose() async {
    _vibrationTimer?.cancel();
    await stopAlert();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
