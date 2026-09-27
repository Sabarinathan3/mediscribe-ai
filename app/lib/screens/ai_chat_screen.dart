import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/colors.dart';
import '../services/tts_service.dart';
import 'onboarding_screen.dart'; // Reuse BackgroundPatternPainter for consistent grids

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Seed with a welcoming AI introduction
    _messages.add(
      ChatMessage(
        text: "Hello! I am your AI Health Assistant. Ask me anything about your scanned prescriptions, drug interactions, side effects, or medication guidelines.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response stream
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      String aiResponse = "";
      final query = text.toLowerCase();
      
      if (query.contains("side effect") || query.contains("sildenafil")) {
        aiResponse = "Common side effects of sildenafil include headaches, facial flushing, indigestion, nasal congestion, and mild visual changes. Please consult a doctor immediately if you experience severe side effects or vision loss.";
      } else if (query.contains("aspirin") || query.contains("ibuprofen")) {
        aiResponse = "Warning: Aspirin and Ibuprofen are both NSAIDs. Taking them together increases the risk of severe gastrointestinal side effects like stomach bleeding, ulcers, and kidney impairment.";
      } else if (query.contains("metformin")) {
        aiResponse = "Metformin is typically prescribed for Type 2 Diabetes. It is best taken with meals to reduce gastrointestinal side effects (like nausea or cramping). Ensure you stay hydrated.";
      } else {
        aiResponse = "I can analyze your medications to help you understand them better. For safety, please cross-reference any advice with your healthcare professional.";
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _startVoiceInput() {
    // Show premium simulated voice recording overlay waveform
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _VoiceRecordingOverlay(
          onSpeechComplete: (recognizedText) {
            Navigator.pop(context);
            if (recognizedText.isNotEmpty) {
              _messageController.text = recognizedText;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Painter Grid
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                _buildHeader(isDark),

                // Conversation Message Feed
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], isDark),
                  ),
                ),

                // Typing indicator loader
                if (_isTyping) _buildTypingIndicator(isDark),

                // Prompt Suggestions Pill row
                if (!_isTyping) _buildSuggestionsRow(isDark),

                // Input Bar Action layout
                _buildInputBar(isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Health Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online · Safe Guidance',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final ttsState = ref.watch(ttsNotifierProvider);
    final isPlaying = ttsState.playState == TtsPlayState.playing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: msg.isUser ? AppColors.primaryGradient : null,
                color: msg.isUser ? null : (isDark ? AppColors.surfaceCardDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF374151)),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  if (!msg.isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // TTS Trigger button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                            size: 16,
                            color: const Color(0xFF6C63FF),
                          ),
                          onPressed: () {
                            final notifier = ref.read(ttsNotifierProvider.notifier);
                            if (isPlaying) {
                              notifier.stop();
                            } else {
                              notifier.speak(msg.text);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF0FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF6C63FF)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceCardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Text('AI is thinking', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                _bouncingDot(0),
                _bouncingDot(1),
                _bouncingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bouncingDot(int index) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: const BoxDecoration(
        color: Color(0xFF6C63FF),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.7, end: 1.3, duration: 400.ms, delay: (index * 150).ms);
  }

  Widget _buildSuggestionsRow(bool isDark) {
    final suggestions = [
      "Metformin instructions?",
      "Aspirin + Ibuprofen conflict",
      "Sildenafil side effects",
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => _sendMessage(suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
            ),
            child: Text(
              suggestions[i],
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Audio Speech input button
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Color(0xFF6C63FF)),
            onPressed: _startVoiceInput,
          ),
          const SizedBox(width: 8),

          // Text Field Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceCardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your prescription...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Simulated Voice Input Overlay with wave
// ==========================================
class _VoiceRecordingOverlay extends StatefulWidget {
  final Function(String) onSpeechComplete;

  const _VoiceRecordingOverlay({required this.onSpeechComplete});

  @override
  State<_VoiceRecordingOverlay> createState() => _VoiceRecordingOverlayState();
}

class _VoiceRecordingOverlayState extends State<_VoiceRecordingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Trigger mock recognition completion after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onSpeechComplete("What are the side effects of Metformin?");
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Listening to Medical Speech...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Bouncing Audio Waves representation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              7,
              (idx) => AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final height = 15.0 + 30.0 * (0.3 + 0.7 * (idx % 2 == 0 ? _animController.value : 1.0 - _animController.value));
                  return Container(
                    width: 6,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '"What are the side effects of Metformin?"',
            style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
