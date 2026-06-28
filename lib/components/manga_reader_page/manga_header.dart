import 'package:flutter/material.dart';
import 'package:zenbu/models/extensions_models.dart';

class MangaHeader extends StatelessWidget implements PreferredSizeWidget {
  final String mangaTitle;
  final ExtEpisode chapter;
  final bool isWebtoonMode;
  final VoidCallback onToggleReadingMode;
  final VoidCallback onBackPressed;

  const MangaHeader({
    super.key,
    required this.mangaTitle,
    required this.chapter,
    required this.isWebtoonMode,
    required this.onToggleReadingMode,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackPressed,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mangaTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              chapter.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isWebtoonMode ? Icons.view_day : Icons.swap_horizontal_circle,
              color: Colors.white,
            ),
            tooltip: isWebtoonMode
                ? 'Switch to Single Page'
                : 'Switch to Webtoon Scroll',
            onPressed: onToggleReadingMode,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
