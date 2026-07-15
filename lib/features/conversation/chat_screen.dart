import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'conversation_provider.dart';
import '../../core/audio/voice_activity_detector.dart';
import '../learning/flashcard_screen.dart';
import 'camera_scanner.dart';

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
  
  bool _handsFreeMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(conversationProvider.notifier).startSession(widget.memberId));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  void _toggleHandsFree() {
    setState(() {
      _handsFreeMode = !_handsFreeMode;
    });

    final vadNotifier = ref.read(vadProvider.notifier);
    if (_handsFreeMode) {
      vadNotifier.startVAD();
    } else {
      vadNotifier.stopVAD();
    }
  }

  void _triggerWakeWord(String phrase) {
    ref.read(vadProvider.notifier).triggerWakeWord(phrase, (action) {
      String message = "Aarav said: $phrase";
      _send(message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Event Triggered: $action'),
          backgroundColor: const Color(0xFF06B6D4),
        ),
      );
    });
  }

  void _handleInterceptCommand(String rawCommand) {
    final parts = rawCommand.split('|');
    if (parts.isEmpty) return;
    
    final cmd = parts[0].replaceAll('COMMAND:', '');
    final cmdParts = cmd.split(':');
    if (cmdParts.length < 2) return;

    final type = cmdParts[0];
    final target = cmdParts[1];

    if (!mounted) return;
    final navigator = Navigator.of(context);

    if (type == 'launch_deck') {
      Future.microtask(() {
        navigator.push(
          MaterialPageRoute(builder: (context) => FlashcardScreen(deckType: target)),
        );
      });
    } else if (type == 'launch_app') {
      Future.microtask(() {
        if (!mounted) return;
        _showAppLauncherDialog(target);
      });
    }
  }

  void _showAppLauncherDialog(String appName) {
    showDialog(
      context: context,
      builder: (context) {
        Timer(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF0F172A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              Icon(
                appName == 'facebook'
                    ? Icons.facebook
                    : appName == 'instagram'
                        ? Icons.camera_alt
                        : Icons.local_taxi,
                size: 80,
                color: const Color(0xFF818CF8),
              ),
              const SizedBox(height: 16),
              Text(
                'Launching ${appName.toUpperCase()}...',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transitioning to third-party app secure sandbox.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _triggerFaceScanner() {
    showDialog(
      context: context,
      builder: (context) {
        return CameraScanner(
          userName: widget.nickname,
          onGreetingTriggered: (greeting) {
            _send(greeting);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ConversationState chatState = ref.watch(conversationProvider);
    final VadModel vad = ref.watch(vadProvider);
    
    ref.listen<ConversationState>(conversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        
        if (next.messages.isNotEmpty) {
          final lastMsg = next.messages.last;
          if (!lastMsg.isUser && lastMsg.text.startsWith('COMMAND:')) {
            _handleInterceptCommand(lastMsg.text);
          }
        }
      }
    });

    ref.listen<VadModel>(vadProvider, (prev, next) {
      if (next.state == VadState.processing && prev?.state != VadState.processing) {
        _send("Aarav is speaking: Tell me about space!");
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
            icon: const Icon(Icons.camera_front, color: Colors.greenAccent),
            onPressed: _triggerFaceScanner,
            tooltip: 'Trigger Face Scan Greeting',
          ),
          IconButton(
            icon: Icon(
              _handsFreeMode ? Icons.headset_mic : Icons.headset_off,
              color: _handsFreeMode ? Colors.greenAccent : const Color(0xFF6366F1),
            ),
            onPressed: _toggleHandsFree,
            tooltip: _handsFreeMode ? 'Disable Hands-Free VAD' : 'Enable Hands-Free VAD',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive Female AI Anchor Avatar Representation Card
            _buildAvatarCard(chatState, vad),
            Expanded(
              child: chatState.messages.isEmpty && chatState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        String displayText = msg.text;
                        if (displayText.startsWith('COMMAND:')) {
                          final split = displayText.split('|');
                          if (split.length > 1) displayText = split[1];
                        }
                        return _buildChatBubble(msg, displayText);
                      },
                    ),
            ),
            if (chatState.isLoading || vad.state == VadState.processing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vad.state == VadState.processing ? 'Speech Detected... Transcribing...' : 'AI Dost is thinking...',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (!_handsFreeMode) _buildQuickSuggestionRow(),
            _handsFreeMode ? _buildHandsFreeArea(vad) : _buildTextInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(ConversationState chatState, VadModel vad) {
    IconData avatarIcon = Icons.face;
    String statusLabel = 'Idle';
    Color iconColor = Colors.white70;

    if (chatState.isLoading) {
      avatarIcon = Icons.record_voice_over;
      statusLabel = 'Speaking';
      iconColor = const Color(0xFF06B6D4);
    } else if (vad.state == VadState.speaking) {
      avatarIcon = Icons.hearing;
      statusLabel = 'Listening';
      iconColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF0F172A),
            child: Icon(avatarIcon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kia - AI News Anchor Model',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chatState.isLoading || vad.state == VadState.speaking ? Colors.green : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'State: $statusLabel',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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

  Widget _buildQuickSuggestionRow() {
    final List<String> suggestions = [
      '1+2',
      'Open math deck',
      'Open English deck',
      'Open Facebook',
      'Open Insta',
      'Open Ola App'
    ];

    return Container(
      height: 48,
      color: const Color(0xFF0B0F19),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF1E293B),
              side: const BorderSide(color: Color(0xFF334155)),
              label: Text(item, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11)),
              onPressed: () => _send(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, String text) {
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
              text,
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

  Widget _buildHandsFreeArea(VadModel vad) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vad.state == VadState.sleep
                    ? Icons.bedtime
                    : vad.state == VadState.speaking
                        ? Icons.volume_up
                        : Icons.graphic_eq,
                color: vad.state == VadState.speaking ? Colors.greenAccent : const Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              Text(
                vad.state == VadState.sleep
                    ? 'App is on Table (Sleep Mode)'
                    : vad.state == VadState.speaking
                        ? 'VAD: User Speaking...'
                        : 'VAD: Listening hands-free...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              7,
              (index) {
                double height = 5.0 + (vad.dbLevel - 30) * (index % 3 + 1) * 0.4;
                if (height > 50) height = 50;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: height,
                  decoration: BoxDecoration(
                    color: vad.state == VadState.speaking ? Colors.greenAccent : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('SIMULATE WAKE WORD TRIGGERS:', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildWakeButton('Hi Kia, play Hindi song'),
              _buildWakeButton('Hi Kia, start movie'),
              _buildWakeButton('Hi Kia, play rhyme'),
              _buildWakeButton('Where are you Kia?'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWakeButton(String label) {
    return ActionChip(
      backgroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF334155)),
      label: Text(label, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11)),
      onPressed: () => _triggerWakeWord(label),
    );
  }
}
