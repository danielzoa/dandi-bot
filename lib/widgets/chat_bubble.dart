import 'package:flutter/material.dart';

import '../enums/ai_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.blue.withValues(alpha: 0.88)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUser ? AppColors.blueBright : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(message.content, style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text(
                  isUser
                      ? Formatters.time(message.createdAt)
                      : '${message.provider?.label ?? AiProvider.mock.label} • ${Formatters.time(message.createdAt)}',
                  style: AppTextStyles.muted.copyWith(
                    color: isUser
                        ? AppColors.white.withValues(alpha: 0.72)
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
