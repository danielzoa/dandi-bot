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
    final groupedArticles = <String, List<NewsArticle>>{};
    final sortedArticles = [...controller.newsArticles]
      ..sort((a, b) {
        final aDate = a.publishedAt;
        final bDate = b.publishedAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    for (final article in sortedArticles) {
      groupedArticles.putIfAbsent(article.category, () => []).add(article);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Noticias', style: AppTextStyles.display),
                  const SizedBox(height: 6),
                  Text(
                    updatedAt == null
                        ? 'Radar das ultimas 72 horas usado pelos agentes.'
                        : 'Atualizado as ${DateFormat.Hm('pt_BR').format(updatedAt)}. Mais novas primeiro.',
                    style: AppTextStyles.muted,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: controller.isRefreshingNews
                  ? null
                  : controller.refreshNews,
              icon: controller.isRefreshingNews
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (controller.newsArticles.isEmpty)
          DandiCard(
            child: Text(
              controller.isRefreshingNews
                  ? 'Consultando o radar dos agentes...'
                  : controller.isBackendOnline
                  ? 'Nenhuma noticia verificavelmente recente foi encontrada nas ultimas 72 horas.'
                  : 'Nao foi possivel carregar noticias. Verifique se o backend esta online.',
              style: AppTextStyles.muted,
            ),
          )
        else
          for (final entry in groupedArticles.entries) ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _categoryIcon(entry.key),
                        color: AppColors.blueBright,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _categoryLabel(entry.key),
                        style: AppTextStyles.title,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.value.length} noticias',
                  style: AppTextStyles.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 980
                    ? 3
                    : constraints.maxWidth > 620
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entry.value.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 4.2 : 3.2,
                  ),
                  itemBuilder: (context, index) =>
                      _NewsCard(article: entry.value[index]),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

String _categoryLabel(String category) {
  return switch (category.toLowerCase()) {
    'macro' => 'Macroeconomia',
    'mercados' => 'Mercados',
    'geopolitica' => 'Geopolitica',
    'commodities' => 'Commodities',
    final value => value.toUpperCase(),
  };
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'macro' => Icons.account_balance_outlined,
    'mercados' => Icons.query_stats_rounded,
    'geopolitica' => Icons.public_rounded,
    'commodities' => Icons.oil_barrel_outlined,
    _ => Icons.newspaper_rounded,
  };
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  String get _publishedLabel {
    final publishedAt = article.publishedAt;
    if (publishedAt == null) return 'Horario nao informado';
    return DateFormat(
      'dd/MM/yyyy - HH:mm',
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
            'A fonte nao disponibilizou um link para esta noticia.',
          ),
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir a noticia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      onTap: () => _openArticle(context),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.42)),
            ),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.article_outlined,
                color: AppColors.blueBright,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 5),
                Text(
                  '${article.agentName}  |  ${article.source}  |  $_publishedLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.open_in_new_rounded,
            size: 17,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}
