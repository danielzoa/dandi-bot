import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../services/app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NewsStrip extends StatelessWidget {
  const NewsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final articles = controller.newsArticles.take(3).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.newspaper_rounded, color: AppColors.blueBright),
            const SizedBox(width: 10),
            Text('Radar dos agentes', style: AppTextStyles.subtitle),
            const SizedBox(width: 14),
            Expanded(
              child: articles.isEmpty
                  ? Text(
                      controller.isRefreshingNews
                          ? 'Atualizando noticias...'
                          : 'Noticias disponiveis quando o backend estiver online.',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted,
                    )
                  : Text(
                      articles.map((article) => article.title).join('  |  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted.copyWith(
                        color: AppColors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => context.go(routeNews),
              child: const Text('Ver guia'),
            ),
          ],
        ),
      ),
    );
  }
}
