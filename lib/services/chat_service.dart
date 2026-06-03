import '../models/chat_message.dart';

abstract class ChatService {
  Future<ChatMessage> sendMessage(
    String content, {
    String? contextTicker,
    List<ChatMessage> history = const [],
    String? apiKey,
  });

  List<String> getDynamicSuggestions({
    String? lastAnalyzedTicker,
    bool hasPortfolio = false,
  });
}
