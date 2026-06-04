import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String get _publishedLabel {
    final publishedAt = article.publishedAt;
    if (publishedAt == null) return 'Horário não informado';
    return DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
      'pt_BR',
    ).format(publishedAt.toLocal());
  }

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(article.url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A fonte não disponibilizou um link para esta notícia.',
          ),
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a notícia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      onTap: () => _openArticle(context),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      article.source,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _publishedLabel,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted.copyWith(fontSize: 11),
                    ),
                  ],
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Abrir notícia',
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.blueBright,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: AppColors.blueBright,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
