/// World Cup news article from Kickora backend (`GET /news/world-cup`).
class NewsArticleModel {
  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.imageUrl,
    required this.url,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String source;
  final String imageUrl;
  final String url;
  final DateTime? publishedAt;

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      id: (json['id'] ?? json['url'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? json['description'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['urlToImage'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
    );
  }
}

/// Result envelope for World Cup news fetch.
class WorldCupNewsResult {
  const WorldCupNewsResult({
    required this.configured,
    required this.fallback,
    required this.articles,
    this.errorMessage,
  });

  final bool configured;
  final bool fallback;
  final List<NewsArticleModel> articles;
  final String? errorMessage;

  factory WorldCupNewsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['articles'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NewsArticleModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <NewsArticleModel>[];

    return WorldCupNewsResult(
      configured: json['configured'] == true,
      fallback: json['fallback'] == true,
      articles: list,
      errorMessage: json['error']?.toString(),
    );
  }

  static const notConfigured = WorldCupNewsResult(
    configured: false,
    fallback: false,
    articles: [],
  );
}
