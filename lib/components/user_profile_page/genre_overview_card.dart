import 'package:flutter/material.dart';

class GenreOverviewCard extends StatelessWidget {
  const GenreOverviewCard({
    super.key,
    required this.title,
    required this.genres,
  });

  final String title;
  final List<Map<String, dynamic>> genres;

  static const Map<String, Color> _genreColors = {
    'Action': Color(0xFF7CB342),
    'Adventure': Color(0xFFFFB300),
    'Comedy': Color(0xFF03A9F4),
    'Drama': Color(0xFFEC407A),
    'Fantasy': Color(0xFFAB47BC),
    'Mystery': Color(0xFF3F51B5),
    'Psychological': Color(0xFF424242),
    'Romance': Color(0xFF7CB342),
    'Sci-Fi': Color(0xFF00ACC1),
    'Slice of Life': Color(0xFFAB47BC),
    'Supernatural': Color(0xFF5E35B1),
    'Thriller': Color(0xFFD84315),
    'Ecchi': Color(0xFFEF5350),
    'Hentai': Color(0xFFC62828),
    'Sports': Color(0xFF00897B),
    'Music': Color(0xFFF06292),
    'Mecha': Color(0xFF5C6BC0),
  };

  Color _getGenreColor(String genre) {
    if (_genreColors.containsKey(genre)) {
      return _genreColors[genre]!;
    }
    final hash = genre.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (genres.isEmpty) {
      return Container();
    }

    final List<_GenreItem> topGenres = [];
    final limit = genres.length > 5 ? 5 : genres.length;
    for (int i = 0; i < limit; i++) {
      final name = genres[i]['genre'] as String;
      final count = genres[i]['count'] as int;
      topGenres.add(
        _GenreItem(name: name, count: count, color: _getGenreColor(name)),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.onInverseSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: topGenres.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.count} Entries',
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                width: double.infinity,
                child: Row(
                  children: topGenres.map((item) {
                    return Expanded(
                      flex: item.count,
                      child: Container(color: item.color),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreItem {
  final String name;
  final int count;
  final Color color;

  const _GenreItem({
    required this.name,
    required this.count,
    required this.color,
  });
}
