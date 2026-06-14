// lib/services/audio_service.dart
//
// Manages TTS audio playback using the `audioplayers` package.
// Accepts base64-encoded WAV audio from the backend, writes it to a temp file,
// and plays it. Exposes streams so the UI can react to play/stop state.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum AudioPlaybackState { idle, loading, playing, stopped, error }

// ─── AudioService ─────────────────────────────────────────────────────────────

/// Plays TTS audio received as base64 from the backend.
///
/// Usage:
/// ```dart
/// final audio = AudioService();
/// await audio.playBase64(base64String);
/// // later:
/// await audio.stop();
/// ```
class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  AudioPlaybackState _state = AudioPlaybackState.idle;
  String? _lastError;
  File? _currentFile;

  StreamSubscription? _playerSub;

  AudioPlaybackState get state => _state;
  String? get lastError => _lastError;
  bool get isPlaying => _state == AudioPlaybackState.playing;
  bool get isLoading => _state == AudioPlaybackState.loading;

  AudioService() {
    _player.onPlayerStateChanged.listen((ps) {
      if (ps == PlayerState.completed || ps == PlayerState.stopped) {
        _setState(AudioPlaybackState.stopped);
        _cleanupTempFile();
      }
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Decode [base64Audio] and play as WAV.
  /// [format] defaults to 'wav' — must match what the backend returns.
  Future<void> playBase64(String base64Audio, {String format = 'wav'}) async {
    if (base64Audio.isEmpty) {
      _setError('Received empty audio data from backend.');
      return;
    }

    try {
      _setState(AudioPlaybackState.loading);

      // Stop any current playback
      await _player.stop();
      await _cleanupTempFile();

      // Decode base64 → bytes
      final bytes = base64Decode(base64Audio);
      if (bytes.isEmpty) {
        throw Exception('Decoded audio bytes are empty.');
      }

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/smartaid_tts_${DateTime.now().millisecondsSinceEpoch}.$format';
      _currentFile = File(path);
      await _currentFile!.writeAsBytes(bytes);

      debugPrint('[AudioService] Playing TTS audio (${bytes.length} bytes) from $path');

      await _player.play(DeviceFileSource(path));
      _setState(AudioPlaybackState.playing);
    } catch (e) {
      debugPrint('[AudioService] Error playing audio: $e');
      _setError('Could not play audio: $e');
    }
  }

  /// Stop current playback.
  Future<void> stop() async {
    await _player.stop();
    _setState(AudioPlaybackState.stopped);
    await _cleanupTempFile();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────────

  Future<void> _cleanupTempFile() async {
    try {
      if (_currentFile != null && await _currentFile!.exists()) {
        await _currentFile!.delete();
      }
    } catch (_) {}
    _currentFile = null;
  }

  void _setState(AudioPlaybackState newState) {
    _state = newState;
    _lastError = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _lastError = msg;
    _state = AudioPlaybackState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    _cleanupTempFile();
    super.dispose();
  }
}
