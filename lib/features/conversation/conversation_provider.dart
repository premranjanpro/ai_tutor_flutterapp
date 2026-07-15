import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ConversationState {
  final String? sessionId;
  final List<ChatMessage> messages;
  final bool isLoading;

  ConversationState({
    this.sessionId,
    this.messages = const [],
    this.isLoading = false,
  });

  ConversationState copyWith({
    String? sessionId,
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ConversationState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ConversationNotifier extends Notifier<ConversationState> {
  @override
  ConversationState build() {
    return ConversationState();
  }

  Future<void> startSession(String memberId) async {
    state = ConversationState(isLoading: true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/conversation', data: {
        'memberId': memberId,
        'conversationType': 'General',
      });

      if (response.data['success'] == true) {
        state = ConversationState(
          sessionId: response.data['data']['id'],
          messages: [
            ChatMessage(
              text: "Beep Boop! Hello! I am Ghar Ka AI Teacher. Let's start talking!",
              isUser: false,
              timestamp: DateTime.now().toUtc(),
            )
          ],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (state.sessionId == null || text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now().toUtc());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post(
        '/api/conversation/${state.sessionId}/messages',
        data: {'messageText': text},
      );

      if (response.data['success'] == true) {
        final aiText = response.data['data'] as String;
        final aiMsg = ChatMessage(text: aiText, isUser: false, timestamp: DateTime.now().toUtc());
        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final conversationProvider = NotifierProvider<ConversationNotifier, ConversationState>(() {
  return ConversationNotifier();
});
