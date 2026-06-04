class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.category,
    this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? 'Sem título',
      summary: json['summary'] as String? ?? '',
      source: json['source'] as String? ?? 'Yahoo Finance',
      url: json['url'] as String? ?? '',
      category: json['category'] as String? ?? 'mercados',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }

  final String title;
  final String summary;
  final String source;
  final String url;
  final String category;
  final DateTime? publishedAt;
}
