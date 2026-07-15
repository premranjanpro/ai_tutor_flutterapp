import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'conversation_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String nickname;

  const ChatScreen({super.key, required this.memberId, required this.nickname});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _voiceMode = false;
  bool _isRecording = false;
  double _pulseScale = 1.0;
  Timer? _pulseTimer;
  Timer? _speechTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(conversationProvider.notifier).startSession(widget.memberId));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send(String text) async {
    if (text.isEmpty) return;
    await ref.read(conversationProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _toggleVoiceMode() {
    setState(() {
      _voiceMode = !_voiceMode;
      _isRecording = false;
      _pulseScale = 1.0;
      _pulseTimer?.cancel();
      _speechTimer?.cancel();
    });
  }

  void _startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
    });

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        _pulseScale = _pulseScale == 1.0 ? 1.3 : 1.0;
      });
    });

    // Simulate Speech-to-Text translation after 3 seconds
    _speechTimer = Timer(const Duration(seconds: 3), () async {
      _stopRecording();
      final mockSpeechText = 'Hello Dost! Teach me mathematics.';
      await _send(mockSpeechText);
    });
  }

  void _stopRecording() {
    _pulseTimer?.cancel();
    _speechTimer?.cancel();
    setState(() {
      _isRecording = false;
      _pulseScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ConversationState chatState = ref.watch(conversationProvider);
    
    ref.listen<ConversationState>(conversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talking to AI Dost',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Speaking with ${widget.nickname}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_voiceMode ? Icons.keyboard : Icons.mic, color: const Color(0xFF6366F1)),
            onPressed: _toggleVoiceMode,
            tooltip: _voiceMode ? 'Switch to Keyboard' : 'Switch to Voice Mode',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty && chatState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildChatBubble(msg);
                      },
                    ),
            ),
            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Dost is thinking...',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            _voiceMode ? _buildVoiceInputArea() : _buildTextInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isMe = message.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('hh:mm a').format(message.timestamp.toLocal()),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              onSubmitted: (val) {
                _send(val.trim());
                _textController.clear();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0B0F19),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF6366F1),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                _send(_textController.text.trim());
                _textController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          Text(
            _isRecording ? 'Listening...' : 'Tap Mic to Speak',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              transformAlignment: Alignment.center,
              transform: Matrix4.diagonal3Values(_pulseScale, _pulseScale, 1.0),
              decoration: BoxDecoration(
                color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 12),
            const Text(
              'Simulating voice speech transmission...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            )
          ]
        ],
      ),
    );
  }
}
