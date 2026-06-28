import 'package:flutter/material.dart';

class MangaBottomControls extends StatelessWidget {
  final int currentPageIndex;
  final int totalPages;
  final int currentChapterIndex;
  final int totalChapters;
  final VoidCallback? onPrevChapter;
  final VoidCallback? onNextChapter;

  const MangaBottomControls({
    super.key,
    required this.currentPageIndex,
    required this.totalPages,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.onPrevChapter,
    required this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.95)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Page ${currentPageIndex + 1} / $totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: onPrevChapter,
                icon: const Icon(Icons.skip_previous, size: 18),
                label: const Text('Prev'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              Text(
                'Chapter ${currentChapterIndex + 1} of $totalChapters',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              ElevatedButton.icon(
                onPressed: onNextChapter,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
