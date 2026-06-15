import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/news_article_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_box.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';

/// Real World Cup news tab — loads from backend only when opened.
class WorldCupNewsTab extends StatelessWidget {
  const WorldCupNewsTab({
    super.key,
    required this.loader,
    required this.isArabic,
  });

  final WorldCupHubLoader loader;
  final bool isArabic;

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    if (isArabic) {
      return '${date.day}/${date.month}/${date.year}';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (loader.newsLoading && !loader.newsLoaded) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 120),
          SizedBox(height: 10),
          SkeletonBox(height: 120),
        ],
      );
    }

    final result = loader.newsResult;
    final articles = result.articles;

    if (loader.newsError != null) {
      return RefreshIndicator(
        onRefresh: loader.refreshNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: AppEmptyState(
                icon: Icons.cloud_off_outlined,
                title: isArabic ? 'تعذّر تحميل الأخبار' : 'Could not load news',
                subtitle: loader.newsError ?? '',
                actionLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                onAction: () => loader.loadNews(force: true),
              ),
            ),
          ],
        ),
      );
    }

    if (!result.configured) {
      return RefreshIndicator(
        onRefresh: loader.refreshNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: AppEmptyState(
                icon: Icons.article_outlined,
                title: isArabic
                    ? 'الأخبار غير متاحة حالياً'
                    : 'News not available',
                subtitle: isArabic
                    ? 'مزود الأخبار غير مُعدّ على الخادم. أضف NEWS_API_KEY إلى backend.'
                    : 'News provider is not configured on the backend (NEWS_API_KEY).',
              ),
            ),
          ],
        ),
      );
    }

    if (articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: loader.refreshNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: AppEmptyState(
                icon: Icons.newspaper_outlined,
                title: isArabic ? 'لا توجد أخبار' : 'No news',
                subtitle: isArabic
                    ? 'جرّب التحديث لاحقاً.'
                    : 'Try refreshing later.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loader.refreshNews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SectionHeader(
            title: isArabic ? 'أخبار كأس العالم' : 'World Cup news',
            icon: Icons.article_outlined,
          ),
          if (result.fallback) ...[
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'عرض أخبار كرة القدم الدولية — لا توجد مقالات كأس العالم حالياً.'
                  : 'Showing international football news — no World Cup articles right now.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final article in articles)
            _NewsCard(
              article: article,
              isArabic: isArabic,
              dateLabel: _formatDate(article.publishedAt),
              onTap: () => _openArticle(article.url),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.article,
    required this.isArabic,
    required this.dateLabel,
    required this.onTap,
  });

  final NewsArticleModel article;
  final bool isArabic;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (article.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: article.imageUrl,
                height: 160,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (article.source.isNotEmpty)
                        Expanded(
                          child: Text(
                            article.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
