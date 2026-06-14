// lib/services/chatbot_service.dart
//
// Orchestrates the full voice-to-voice pipeline:
//   1. Send text query → POST /api/first-aid/chat → get text response
//   2. (Optional) Convert response text → POST /api/voice/tts → get base64 audio
//
// Also wraps plain text chat (unchanged from FirstAidChatService).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class ChatResponse {
  final String text;
  final String? severity;

  const ChatResponse({required this.text, this.severity});
}

class VoiceChatResponse {
  final String text;
  final String? severity;
  final String? audioBase64; // null if TTS failed or was skipped

  const VoiceChatResponse({
    required this.text,
    this.severity,
    this.audioBase64,
  });

  bool get hasAudio => audioBase64 != null && audioBase64!.isNotEmpty;
}

// ─── ChatbotService ───────────────────────────────────────────────────────────

/// Provides text chat and voice-enabled chat with the SmartAid first-aid bot.
class ChatbotService {
  // ── Text Chat ─────────────────────────────────────────────────────────────────

  /// Send a plain text query to the chatbot.
  Future<ChatResponse> sendMessage(String query) async {
    final uri = Uri.parse(ApiConfig.firstAidChat);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['response']?.toString().trim() ?? '';
      if (text.isEmpty) throw Exception('Empty response from chatbot');
      final severity = _extractSeverity(text);
      final cleaned = _stripSeverityLine(text);
      return ChatResponse(text: cleaned, severity: severity);
    }

    throw Exception('Chatbot request failed: ${response.statusCode}');
  }

  // ── Voice Chat ────────────────────────────────────────────────────────────────

  /// Send a voice query: text → chat API → TTS → return combined result.
  ///
  /// [language] is passed to the TTS endpoint so Groq can hint its voice.
  /// If TTS fails, returns the text response with [audioBase64] == null.
  Future<VoiceChatResponse> sendVoiceQuery({
    required String text,
    String language = 'en',
  }) async {
    // 1. Get chatbot answer
    final chatResp = await sendMessage(text);

    // 2. Convert chatbot answer to speech (non-blocking failure)
    String? audioBase64;
    try {
      audioBase64 = await _generateTts(chatResp.text, language);
    } catch (e) {
      debugPrint('[ChatbotService] TTS failed (non-fatal): $e');
      // audioBase64 stays null — caller shows text only
    }

    return VoiceChatResponse(
      text: chatResp.text,
      severity: chatResp.severity,
      audioBase64: audioBase64,
    );
  }

  // ── TTS ───────────────────────────────────────────────────────────────────────

  /// Call the backend TTS endpoint and return base64 WAV audio.
  Future<String?> generateTts(String text, {String language = 'en'}) async {
    return _generateTts(text, language);
  }

  Future<String?> _generateTts(String text, String language) async {
    // Truncate very long responses before sending to TTS
    const maxTtsChars = 500;
    final ttsText =
        text.length > maxTtsChars ? '${text.substring(0, maxTtsChars)}…' : text;

    final uri = Uri.parse(ApiConfig.voiceTts);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': ttsText, 'language': language}),
        )
        .timeout(ApiConfig.voiceTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final audio = data['audio_base64']?.toString();
      if (audio == null || audio.isEmpty) {
        throw Exception('Backend returned empty audio_base64');
      }
      return audio;
    }

    String errMsg = 'TTS failed (HTTP ${response.statusCode})';
    try {
      final err = jsonDecode(response.body);
      errMsg = err['detail']?.toString() ?? errMsg;
    } catch (_) {}
    throw Exception(errMsg);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String? _extractSeverity(String text) {
    final match =
        RegExp(r'Severity:\s*(low|medium|high)', caseSensitive: false)
            .firstMatch(text);
    return match?.group(1)?.toLowerCase();
  }

  String _stripSeverityLine(String text) {
    return text
        .replaceAll(RegExp(r'^Severity:.*\n?', caseSensitive: false), '')
        .trim();
  }
}
