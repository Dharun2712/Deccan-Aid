// lib/pages/first_aid_chat_page.dart
//
// SmartAid First-Aid Chatbot with Multilingual Voice Assistant
// ────────────────────────────────────────────────────────────
// Features:
//   • Text + voice input (mic button with pulse animation)
//   • Silence-detection auto-stop
//   • Groq Whisper STT via backend (no API key in Flutter)
//   • Groq PlayAI TTS via backend (auto-plays bot responses)
//   • Speaker icon per bot message (tap to stop)
//   • Language picker: EN / HI / TA / KN / TE
//   • Voice enable/disable toggle
//   • Graceful error handling + retry

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../services/chatbot_service.dart';
import '../services/voice_service.dart';
import '../services/audio_service.dart';

// ─── Language Model ───────────────────────────────────────────────────────────

class _Language {
  final String code;
  final String label;
  final String flag;

  const _Language(this.code, this.label, this.flag);
}

const _languages = [
  _Language('en', 'English', '🇬🇧'),
  _Language('hi', 'हिन्दी', '🇮🇳'),
  _Language('ta', 'தமிழ்', '🟠'),
  _Language('kn', 'ಕನ್ನಡ', '🟡'),
  _Language('te', 'తెలుగు', '🟢'),
];

// ─── Chat Message Model ────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? severity;
  final String? audioBase64; // TTS audio for this bot message

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.severity,
    this.audioBase64,
  });

  factory _ChatMessage.user(String text) =>
      _ChatMessage(text: text, isUser: true);

  factory _ChatMessage.bot(String text,
          {String? severity, String? audioBase64}) =>
      _ChatMessage(
          text: text, isUser: false, severity: severity, audioBase64: audioBase64);
}

// ─── Page Widget ───────────────────────────────────────────────────────────────

class FirstAidChatPage extends StatefulWidget {
  const FirstAidChatPage({super.key});

  @override
  State<FirstAidChatPage> createState() => _FirstAidChatPageState();
}

class _FirstAidChatPageState extends State<FirstAidChatPage>
    with TickerProviderStateMixin {
  // Services
  final _chatService = ChatbotService();
  final _voiceService = VoiceService();
  final _audioService = AudioService();

  // Controllers
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // Messages
  final List<_ChatMessage> _messages = [];

  // UI state
  bool _isSending = false;
  bool _isListening = false; // true while processing STT (upload → response)
  bool _voiceEnabled = true;
  int _playingMessageIndex = -1; // index in _messages of currently-playing audio

  // Language
  _Language _selectedLanguage = _languages[0]; // defaults to English

  // Animation controllers
  late AnimationController _micPulseController;
  late AnimationController _listeningController;
  late Animation<double> _micPulseAnimation;
  late Animation<double> _listeningOpacity;

  // Quick commands
  static const List<String> _quickCommands = [
    'Severe bleeding',
    'Burns',
    'Fracture or sprain',
    'Head injury',
    'CPR steps',
    'Choking adult',
  ];

  @override
  void initState() {
    super.initState();

    // Mic pulse (scale animation while recording)
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    // Listening dots opacity
    _listeningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _listeningOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );

    _micPulseController.stop();

    // Voice service — silence detection callback
    _voiceService.onSilenceDetected = (_) {
      if (mounted && _voiceService.isRecording) {
        _stopAndTranscribe();
      }
    };

    // Audio service listener → update UI
    _audioService.addListener(_onAudioStateChanged);
    _voiceService.addListener(_onVoiceStateChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _micPulseController.dispose();
    _listeningController.dispose();
    _voiceService.removeListener(_onVoiceStateChanged);
    _audioService.removeListener(_onAudioStateChanged);
    _voiceService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  // ─── Listeners ─────────────────────────────────────────────────────────────────

  void _onVoiceStateChanged() {
    if (!mounted) return;
    setState(() {
      if (_voiceService.isRecording) {
        _micPulseController.repeat(reverse: true);
      } else {
        _micPulseController.stop();
        _micPulseController.reset();
      }
    });
  }

  void _onAudioStateChanged() {
    if (!mounted) return;
    setState(() {
      if (!_audioService.isPlaying) {
        _playingMessageIndex = -1;
      }
    });
  }

  // ─── Voice Flow ─────────────────────────────────────────────────────────────────

  Future<void> _handleMicTap() async {
    if (_voiceService.isRecording) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isSending) return;

    final ok = await _voiceService.startRecording(
        language: _selectedLanguage.code);
    if (!ok && mounted) {
      _showError(
        _voiceService.lastError ?? 'Could not start recording',
        retryAction: _startRecording,
      );
    }
  }

  Future<void> _stopAndTranscribe() async {
    setState(() => _isListening = true);

    try {
      final result = await _voiceService.stopAndTranscribe(
          language: _selectedLanguage.code);

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() => _isListening = false);
        _showError('Could not recognise speech. Please try again.',
            retryAction: _startRecording);
        return;
      }

      // Populate text field + auto-send
      _controller.text = result.text;
      setState(() => _isListening = false);

      // Small delay so user sees the text before it's sent
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendMessage();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showError('Recognition failed: $e', retryAction: _startRecording);
    }
  }

  // ─── Chat Flow ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage({String? preset}) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.insert(0, _ChatMessage.user(text));
      _isSending = true;
      _controller.clear();
    });
    _scrollToTop();

    try {
      String? audioBase64;
      String botText;
      String? severity;

      if (_voiceEnabled) {
        // Voice pipeline: chat + TTS together
        final resp = await _chatService.sendVoiceQuery(
          text: text,
          language: _selectedLanguage.code,
        );
        botText = resp.text;
        severity = resp.severity;
        audioBase64 = resp.audioBase64;
      } else {
        // Text-only pipeline
        final resp = await _chatService.sendMessage(text);
        botText = resp.text;
        severity = resp.severity;
      }

      if (!mounted) return;

      final botMsg = _ChatMessage.bot(botText,
          severity: severity, audioBase64: audioBase64);

      setState(() {
        _messages.insert(0, botMsg);
        _isSending = false;
      });
      _scrollToTop();

      // Auto-play TTS audio
      if (audioBase64 != null && audioBase64.isNotEmpty && _voiceEnabled) {
        _playAudioForMessage(0, audioBase64);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.insert(
          0,
          _ChatMessage.bot(
            'Sorry, I could not reach the first-aid assistant. '
            'Please check your connection and try again.',
          ),
        );
        _isSending = false;
      });
      _scrollToTop();
      _showError('Network error: $e',
          retryAction: () => _sendMessage(preset: text));
    }
  }

  void _playAudioForMessage(int msgIndex, String base64Audio) async {
    // Stop any existing playback
    await _audioService.stop();

    setState(() => _playingMessageIndex = msgIndex);
    await _audioService.playBase64(base64Audio);

    if (!mounted) return;
    if (_audioService.state == AudioPlaybackState.error) {
      _showError(
          _audioService.lastError ?? 'Could not play audio response.');
    }
  }

  Future<void> _stopAudio() async {
    await _audioService.stop();
    setState(() => _playingMessageIndex = -1);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────────

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.green;
      default:
        return AppTheme.secondary;
    }
  }

  void _showError(String message, {VoidCallback? retryAction}) {
    if (!mounted) return;
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      action: retryAction != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: const Color(0xFFED4C5C),
              onPressed: retryAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snack);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF2F3), Color(0xFFF6FAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBackgroundOrbs(),
              Column(
                children: [
                  _buildHeader(context),
                  _buildCommandStrip(),
                  Expanded(child: _buildChatArea()),
                  _buildComposer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Background Orbs ──────────────────────────────────────────────────────────

  Widget _buildBackgroundOrbs() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFED4C5C).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2A9D8F).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.headerDark),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartAid First-Aid',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerDark,
                  ),
                ),
                Text(
                  'Quick steps for emergency response',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Language selector
          _buildLanguagePicker(),
          const SizedBox(width: 8),
          // Voice toggle
          _buildVoiceToggle(),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Language>(
          value: _selectedLanguage,
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 16, color: AppTheme.headerDark),
          style: GoogleFonts.dmSans(
            color: AppTheme.headerDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (lang) {
            if (lang != null) {
              setState(() => _selectedLanguage = lang);
            }
          },
          items: _languages
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text('${l.flag} ${l.label}'),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildVoiceToggle() {
    return Tooltip(
      message: _voiceEnabled ? 'Voice ON' : 'Voice OFF',
      child: GestureDetector(
        onTap: () async {
          if (_voiceEnabled) await _audioService.stop();
          setState(() => _voiceEnabled = !_voiceEnabled);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _voiceEnabled
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _voiceEnabled
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
          ),
          child: Icon(
            _voiceEnabled ? Icons.volume_up : Icons.volume_off,
            color: _voiceEnabled ? AppTheme.primary : Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ─── Quick Commands Strip ─────────────────────────────────────────────────────

  Widget _buildCommandStrip() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _quickCommands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = _quickCommands[index];
          return ActionChip(
            label: Text(
              label,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            backgroundColor: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            elevation: 2,
            onPressed: () => _sendMessage(preset: label),
          );
        },
      ),
    );
  }

  // ─── Chat Area ────────────────────────────────────────────────────────────────

  Widget _buildChatArea() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              key: const ValueKey('chatList'),
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              reverse: true,
              itemCount: _messages.length +
                  (_isSending || _isListening ? 1 : 0),
              itemBuilder: (context, index) {
                if ((_isSending || _isListening) && index == 0) {
                  return _isListening
                      ? _buildListeningIndicator()
                      : _buildTypingIndicator();
                }
                final msgIndex =
                    (_isSending || _isListening) ? index - 1 : index;
                return _buildMessageBubble(_messages[msgIndex], msgIndex);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.record_voice_over_outlined,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ask anything about first-aid steps',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.headerDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type or tap the mic 🎙️ and speak in\nEnglish, Hindi, Tamil, Kannada, or Telugu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulseDot(0),
            const SizedBox(width: 4),
            _buildPulseDot(1),
            const SizedBox(width: 4),
            _buildPulseDot(2),
            const SizedBox(width: 8),
            Text(
              'SmartAid is thinking…',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFED4C5C).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFED4C5C).withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _listeningController,
              builder: (_, __) => Icon(
                Icons.hearing,
                color: Color.lerp(
                  const Color(0xFFED4C5C).withValues(alpha: 0.5),
                  const Color(0xFFED4C5C),
                  _listeningOpacity.value,
                ),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recognising speech…',
              style: GoogleFonts.dmSans(
                color: const Color(0xFFED4C5C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseDot(int index) {
    return AnimatedBuilder(
      animation: _listeningController,
      builder: (_, __) {
        final delay = index * 0.2;
        final t = (_listeningController.value + delay) % 1.0;
        final opacity = (math.sin(t * math.pi)).clamp(0.3, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ─── Message Bubbles ──────────────────────────────────────────────────────────

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFFED4C5C) : Colors.white;
    final textColor = isUser ? Colors.white : AppTheme.textDark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity badge (bot messages only)
                  if (!isUser && message.severity != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _severityColor(message.severity)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Severity: ${message.severity}',
                        style: GoogleFonts.dmSans(
                          color: _severityColor(message.severity),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // Message text
                  Text(
                    message.text,
                    style: GoogleFonts.dmSans(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Speaker button for bot messages with audio
            if (!isUser && message.audioBase64 != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: _buildSpeakerButton(index, message.audioBase64!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerButton(int msgIndex, String audioBase64) {
    final isPlayingThis = _playingMessageIndex == msgIndex;
    return GestureDetector(
      onTap: () {
        if (isPlayingThis) {
          _stopAudio();
        } else {
          _playAudioForMessage(msgIndex, audioBase64);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isPlayingThis
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPlayingThis
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlayingThis ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
              size: 15,
              color: isPlayingThis ? AppTheme.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              isPlayingThis ? 'Stop' : 'Play',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPlayingThis ? AppTheme.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Composer ─────────────────────────────────────────────────────────────────

  Widget _buildComposer() {
    final isRecording = _voiceService.isRecording;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording amplitude waveform
          if (isRecording) _buildRecordingBar(),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mic button
                _buildMicButton(isRecording),
                const SizedBox(width: 8),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !isRecording && !_isListening,
                    decoration: InputDecoration(
                      hintText: isRecording
                          ? 'Recording… tap mic to stop'
                          : _isListening
                              ? 'Recognising speech…'
                              : 'Describe the emergency or injury',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.dmSans(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                // Send button
                AnimatedOpacity(
                  opacity: (_isSending || isRecording || _isListening) ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed: (_isSending || isRecording || _isListening)
                        ? null
                        : _sendMessage,
                    icon: Icon(
                      Icons.send_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This assistant provides first-aid guidance, not medical diagnosis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(bool isRecording) {
    return GestureDetector(
      onTap: _voiceEnabled ? _handleMicTap : null,
      child: AnimatedBuilder(
        animation: _micPulseAnimation,
        builder: (_, child) {
          return Transform.scale(
            scale: isRecording ? _micPulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring while recording
            if (isRecording)
              AnimatedBuilder(
                animation: _micPulseController,
                builder: (_, __) => Container(
                  width: 44 + _micPulseController.value * 8,
                  height: 44 + _micPulseController.value * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFED4C5C)
                        .withValues(alpha: (0.15 - _micPulseController.value * 0.1).clamp(0.0, 1.0)),
                  ),
                ),
              ),
            // Core button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !_voiceEnabled
                    ? Colors.grey.shade200
                    : isRecording
                        ? const Color(0xFFED4C5C)
                        : AppTheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: !_voiceEnabled
                      ? Colors.grey.shade300
                      : isRecording
                          ? const Color(0xFFED4C5C)
                          : AppTheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: !_voiceEnabled
                    ? Colors.grey
                    : isRecording
                        ? Colors.white
                        : AppTheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return StreamBuilder<double>(
      stream: _voiceService.amplitudeStream,
      builder: (context, snapshot) {
        final amp = snapshot.data ?? -60.0;
        // Normalise dBFS to [0, 1]
        final normalised = ((amp + 60) / 60).clamp(0.0, 1.0);
        return Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(18, (i) {
              final barHeight =
                  6.0 + normalised * 24 * (math.sin(i * 0.7 + DateTime.now().millisecondsSinceEpoch * 0.01).abs());
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: barHeight.clamp(4.0, 28.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFED4C5C)
                      .withValues(alpha: (0.5 + normalised * 0.5).clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
