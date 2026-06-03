import 'package:flutter/material.dart';

import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/dandi_bot_avatar.dart';
import '../../widgets/suggestion_chip_row.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final suggestions = controller.chatService.getDynamicSuggestions(
      lastAnalyzedTicker: controller.selectedAnalysis?.asset.ticker,
      hasPortfolio: controller.portfolioItems.isNotEmpty,
    );
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: height < 760 ? 720 : height - 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DandiBotAvatar(size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chat com IA', style: AppTextStyles.display),
                    Text(
                      'Tire suas dúvidas sobre investimentos',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 920;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      SizedBox(
                        width: 230,
                        child: _SuggestionsPanel(
                          suggestions: suggestions,
                          onSelected: controller.sendChatMessage,
                        ),
                      ),
                    if (wide) const SizedBox(width: 14),
                    Expanded(
                      child: DandiCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            if (!wide) ...[
                              SuggestionChipRow(
                                suggestions: suggestions,
                                onSelected: controller.sendChatMessage,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: controller.chatMessages.isEmpty
                                  ? _EmptyChat()
                                  : ListView.separated(
                                      itemCount:
                                          controller.chatMessages.length +
                                          (controller.isChatTyping ? 1 : 0),
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        if (index >=
                                            controller.chatMessages.length) {
                                          return const _TypingIndicator();
                                        }
                                        return ChatBubble(
                                          message:
                                              controller.chatMessages[index],
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 12),
                            ChatInput(
                              enabled: !controller.isChatTyping,
                              onSend: controller.sendChatMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sugestões rápidas', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          for (final suggestion in suggestions) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onSelected(suggestion),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(suggestion),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DandiBotAvatar(size: 68),
          const SizedBox(height: 12),
          Text('Faça uma pergunta para começar.', style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(
            'O chat responde com conteúdo educativo e simulado.',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text('Dandi Bot está analisando...', style: AppTextStyles.muted),
            ],
          ),
        ),
      ),
    );
  }
}
