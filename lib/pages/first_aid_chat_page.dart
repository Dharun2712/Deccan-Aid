import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/first_aid_chat_service.dart';

class FirstAidChatPage extends StatefulWidget {
  const FirstAidChatPage({Key? key}) : super(key: key);

  @override
  State<FirstAidChatPage> createState() => _FirstAidChatPageState();
}

class _FirstAidChatPageState extends State<FirstAidChatPage>
    with SingleTickerProviderStateMixin {
  final _chatService = FirstAidChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  static const List<String> _quickCommands = [
    'Severe bleeding',
    'Burns',
    'Fracture or sprain',
    'Head injury',
    'CPR steps',
    'Choking adult',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
      final response = await _chatService.sendMessage(text);
      final severity = _extractSeverity(response);
      final cleaned = _stripSeverityLine(response);

      setState(() {
        _messages.insert(0, _ChatMessage.bot(cleaned, severity: severity));
      });
    } catch (error) {
      setState(() {
        _messages.insert(
          0,
          _ChatMessage.bot(
            'Sorry, I could not reach the first-aid assistant. Please try again.',
          ),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String? _extractSeverity(String text) {
    final match = RegExp(r'Severity:\s*(low|medium|high)', caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.toLowerCase();
  }

  String _stripSeverityLine(String text) {
    return text
        .replaceAll(RegExp(r'^Severity:.*\n?', caseSensitive: false), '')
        .trim();
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
                      const Color(0xFFED4C5C).withOpacity(0.25),
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
                      const Color(0xFF2A9D8F).withOpacity(0.2),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.headerDark),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartAid First-Aid',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick steps for emergency response',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.medical_services_outlined,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandStrip() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _quickCommands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final label = _quickCommands[index];
          return ActionChip(
            label: Text(
              label,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            shadowColor: Colors.black.withOpacity(0.08),
            elevation: 3,
            onPressed: () => _sendMessage(preset: label),
          );
        },
      ),
    );
  }

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
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == 0) {
                  return _buildTypingIndicator();
                }
                final message = _messages[_isSending ? index - 1 : index];
                return _buildMessageBubble(message);
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 32,
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
              'Try a quick command above to get instant guidance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade700,
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'SmartAid is thinking...',
          style: GoogleFonts.dmSans(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isUser
        ? const Color(0xFFED4C5C)
        : Colors.white;
    final textColor = message.isUser ? Colors.white : AppTheme.textDark;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser && message.severity != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _severityColor(message.severity).withOpacity(0.12),
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
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Describe the emergency or injury',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: _isSending ? Colors.grey : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? severity;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.severity,
  });

  factory _ChatMessage.user(String text) {
    return _ChatMessage(text: text, isUser: true);
  }

  factory _ChatMessage.bot(String text, {String? severity}) {
    return _ChatMessage(text: text, isUser: false, severity: severity);
  }
}
