// lib/services/voice_service.dart
//
// Handles microphone recording and speech-to-text via the backend.
// Uses the `record` package to capture raw audio → uploads to POST /api/voice/stt.
// No Groq API key is stored here — all AI work happens server-side.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../config/api_config.dart';

// ─── Public enums ─────────────────────────────────────────────────────────────

enum VoiceState {
  idle,
  requestingPermission,
  recording,
  processing, // uploading + waiting for STT response
  error,
}

// ─── Public result type ────────────────────────────────────────────────────────

class SpeechResult {
  final String text;
  final String? languageDetected;

  const SpeechResult({required this.text, this.languageDetected});

  bool get isEmpty => text.trim().isEmpty;
}

// ─── VoiceService ─────────────────────────────────────────────────────────────

/// Records audio from the microphone and converts it to text via the Groq
/// Whisper endpoint on the backend.
///
/// Usage:
/// ```dart
/// final vs = VoiceService();
/// await vs.startRecording();
/// final result = await vs.stopAndTranscribe(language: 'ta');
/// print(result.text);
/// ```
class VoiceService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();

  VoiceState _state = VoiceState.idle;
  String? _lastError;
  String? _recordingPath;

  // Silence detection: auto-stop after this duration of low amplitude
  static const Duration _silenceThreshold = Duration(seconds: 2);
  static const double _silenceAmplitude = -40.0; // dBFS

  Timer? _silenceTimer;
  Timer? _amplitudePoller;
  final _amplitudeController = StreamController<double>.broadcast();

  // Callback triggered automatically on silence detection — set from UI
  void Function(String language)? onSilenceDetected;
  String _currentLanguage = 'en';

  // ── Getters ──────────────────────────────────────────────────────────────────

  VoiceState get state => _state;
  String? get lastError => _lastError;
  bool get isRecording => _state == VoiceState.recording;
  bool get isProcessing => _state == VoiceState.processing;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  // ── Permission ────────────────────────────────────────────────────────────────

  /// Returns true if microphone permission is granted (or just granted now).
  Future<bool> requestPermission() async {
    _setState(VoiceState.requestingPermission);
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _setError('Microphone permission denied. Please enable it in Settings.');
      return false;
    }
    _setState(VoiceState.idle);
    return true;
  }

  Future<bool> hasPermission() async {
    return await Permission.microphone.isGranted;
  }

  // ── Recording ─────────────────────────────────────────────────────────────────

  /// Starts microphone recording.
  /// Returns true on success, false if permission denied or already recording.
  Future<bool> startRecording({String language = 'en'}) async {
    if (_state == VoiceState.recording) return false;

    _currentLanguage = language;
    _lastError = null;

    // Permission check
    final hasmic = await Permission.microphone.isGranted;
    if (!hasmic) {
      final granted = await requestPermission();
      if (!granted) return false;
    }

    try {
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/smartaid_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,   // m4a / AAC — widely supported
        bitRate: 64000,
        sampleRate: 16000,             // 16kHz — optimal for Whisper
        numChannels: 1,                // mono
      );

      await _recorder.start(config, path: _recordingPath!);
      _setState(VoiceState.recording);
      _startSilenceDetection();
      return true;
    } catch (e) {
      _setError('Could not start recording: $e');
      return false;
    }
  }

  /// Stops recording and uploads audio to the backend for transcription.
  /// Returns a [SpeechResult] on success, or throws on error.
  Future<SpeechResult> stopAndTranscribe({String? language}) async {
    _cancelSilenceDetection();

    if (_state != VoiceState.recording) {
      throw StateError('VoiceService is not recording');
    }

    final lang = language ?? _currentLanguage;

    try {
      final path = await _recorder.stop();
      _setState(VoiceState.processing);

      if (path == null) {
        throw Exception('Recording file path is null after stop');
      }

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Recorded audio file is empty or missing');
      }

      final result = await _uploadAudio(file, lang);
      _setState(VoiceState.idle);
      return result;
    } catch (e) {
      _setError('Transcription failed: $e');
      rethrow;
    }
  }

  /// Cancel recording without transcribing.
  Future<void> cancelRecording() async {
    _cancelSilenceDetection();
    try {
      await _recorder.stop();
    } catch (_) {}
    _setState(VoiceState.idle);
  }

  // ── Silence Detection ─────────────────────────────────────────────────────────

  void _startSilenceDetection() {
    _amplitudePoller?.cancel();
    _amplitudePoller =
        Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_state != VoiceState.recording) {
        _amplitudePoller?.cancel();
        return;
      }
      try {
        final amp = await _recorder.getAmplitude();
        final db = amp.current;
        _amplitudeController.add(db);

        if (db < _silenceAmplitude) {
          // Start / reset silence timer
          _silenceTimer ??= Timer(_silenceThreshold, () {
            if (_state == VoiceState.recording) {
              debugPrint('[VoiceService] Silence detected — auto-stop');
              onSilenceDetected?.call(_currentLanguage);
            }
          });
        } else {
          // Sound detected — reset silence timer
          _silenceTimer?.cancel();
          _silenceTimer = null;
        }
      } catch (_) {}
    });
  }

  void _cancelSilenceDetection() {
    _silenceTimer?.cancel();
    _amplitudePoller?.cancel();
    _silenceTimer = null;
    _amplitudePoller = null;
  }

  // ── Upload & Transcription ────────────────────────────────────────────────────

  Future<SpeechResult> _uploadAudio(File audioFile, String language) async {
    final uri = Uri.parse(ApiConfig.voiceStt);
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'audio',
      audioFile.path,
      filename: 'audio.m4a',
    ));

    // Optional language hint for Whisper
    request.fields['language'] = language;

    debugPrint('[VoiceService] Uploading audio (${await audioFile.length()} bytes) → $uri');

    final streamedResponse = await request
        .send()
        .timeout(ApiConfig.voiceTimeout);

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final text = json['text']?.toString().trim() ?? '';
      final detected = json['language_detected']?.toString();
      debugPrint('[VoiceService] STT result: "$text" (lang=$detected)');
      return SpeechResult(text: text, languageDetected: detected);
    }

    // Extract error message from backend
    String errorMsg = 'STT failed (HTTP ${streamedResponse.statusCode})';
    try {
      final err = jsonDecode(responseBody);
      errorMsg = err['detail']?.toString() ?? errorMsg;
    } catch (_) {}
    throw Exception(errorMsg);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────────

  void _setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String msg) {
    _lastError = msg;
    _state = VoiceState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSilenceDetection();
    _amplitudeController.close();
    _recorder.dispose();
    super.dispose();
  }
}
