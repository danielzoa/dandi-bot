import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/news_article.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/analysis_card.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final updatedAt = controller.newsUpdatedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.newspaper_rounded,
              size: 34,
              color: AppColors.blueBright,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guia de Noticias', style: AppTextStyles.display),
                  Text(
                    updatedAt == null
                        ? 'Radar macroeconomico usado pelos agentes'
                        : 'Atualizado as ${DateFormat.Hms('pt_BR').format(updatedAt)} | atualizacao automatica a cada 30s',
                    style: AppTextStyles.muted,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Atualizar agora',
              onPressed: controller.isRefreshingNews
                  ? null
                  : controller.refreshNews,
              icon: controller.isRefreshingNews
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.newsArticles.isEmpty)
          DandiCard(
            child: Text(
              controller.isRefreshingNews
                  ? 'Consultando o radar dos agentes...'
                  : 'Nao foi possivel carregar noticias. Verifique se o backend esta online.',
              style: AppTextStyles.muted,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.newsArticles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.6 : 1.7,
                ),
                itemBuilder: (context, index) =>
                    _NewsCard(article: controller.newsArticles[index]),
              );
            },
          ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: AppTextStyles.muted.copyWith(
                      color: AppColors.blueBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  article.source,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            article.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle,
          ),
          if (article.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                article.summary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
