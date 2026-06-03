import '../enums/ai_provider.dart';
import '../enums/chat_intent.dart';

enum MessageSender { user, bot }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    this.relatedTicker,
    this.intent,
    this.provider,
  });

  final String id;
  final String content;
  final MessageSender sender;
  final DateTime createdAt;
  final String? relatedTicker;
  final ChatIntent? intent;
  final AiProvider? provider;

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'sender': sender.name,
    'createdAt': createdAt.toIso8601String(),
    'relatedTicker': relatedTicker,
    'intent': intent?.name,
    'provider': provider?.name,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: MessageSender.values.byName(json['sender'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      relatedTicker: json['relatedTicker'] as String?,
      intent: json['intent'] == null
          ? null
          : ChatIntent.values.byName(json['intent'] as String),
      provider: json['provider'] == null
          ? null
          : AiProvider.values.byName(json['provider'] as String),
    );
  }
}
