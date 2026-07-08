import 'package:flutter/material.dart';
import 'stats_card.dart';
import 'genre_overview_card.dart';
import 'bar_chart.dart';
import 'pie_chart.dart';
import 'line_chart.dart';
import 'horizontal_staff_list.dart';

class ProfileStatsTab extends StatelessWidget {
  const ProfileStatsTab({
    super.key,
    required this.statistics,
    required this.isAnime,
  });

  final Map<String, dynamic> statistics;
  final bool isAnime;

  @override
  Widget build(BuildContext context) {
    final count = statistics['count'] as int? ?? 0;
    final double meanScore =
        (statistics['meanScore'] as num?)?.toDouble() ?? 0.0;
    final double stdDev =
        (statistics['standardDeviation'] as num?)?.toDouble() ?? 0.0;

    final List statuses = statistics['statuses'] ?? [];
    final planningStat = statuses.firstWhere(
      (s) => s['status'] == 'PLANNING',
      orElse: () => {'count': 0},
    );
    final planningCount = planningStat['count'] as int? ?? 0;

    final List<StatsItemData> statsItems = [];
    if (isAnime) {
      final episodes = statistics['episodesWatched'] as int? ?? 0;
      final minutes = statistics['minutesWatched'] as int? ?? 0;
      final double daysWatched = minutes / 1440.0;
      final double daysPlanned = (planningCount * 12.0 * 24.0) / 1440.0;

      statsItems.addAll([
        StatsItemData(label: 'Total Anime', value: '$count', icon: Icons.movie),
        StatsItemData(
          label: 'Episodes',
          value: '$episodes',
          icon: Icons.play_arrow,
        ),
        StatsItemData(
          label: 'Days Watched',
          value: daysWatched.toStringAsFixed(1),
          icon: Icons.timer,
        ),
        StatsItemData(
          label: 'Days Planned',
          value: daysPlanned.toStringAsFixed(1),
          icon: Icons.calendar_today,
        ),
        StatsItemData(
          label: 'Mean Score',
          value: meanScore > 0 ? meanScore.toStringAsFixed(1) : 'N/A',
          icon: Icons.star,
        ),
        StatsItemData(
          label: 'Std Deviation',
          value: stdDev > 0 ? stdDev.toStringAsFixed(1) : 'N/A',
          icon: Icons.show_chart,
        ),
      ]);
    } else {
      final chapters = statistics['chaptersRead'] as int? ?? 0;
      final volumes = statistics['volumesRead'] as int? ?? 0;

      statsItems.addAll([
        StatsItemData(label: 'Total Manga', value: '$count', icon: Icons.book),
        StatsItemData(
          label: 'Chapters Read',
          value: '$chapters',
          icon: Icons.chrome_reader_mode,
        ),
        StatsItemData(
          label: 'Volumes Read',
          value: '$volumes',
          icon: Icons.library_books,
        ),
        StatsItemData(
          label: 'Planned Manga',
          value: '$planningCount',
          icon: Icons.calendar_today,
        ),
        StatsItemData(
          label: 'Mean Score',
          value: meanScore > 0 ? meanScore.toStringAsFixed(1) : 'N/A',
          icon: Icons.star,
        ),
        StatsItemData(
          label: 'Std Deviation',
          value: stdDev > 0 ? stdDev.toStringAsFixed(1) : 'N/A',
          icon: Icons.show_chart,
        ),
      ]);
    }

    final List genresRaw = statistics['genres'] ?? [];
    final List<Map<String, dynamic>> genres =
        genresRaw
            .map(
              (g) => {
                'genre': g['genre'] as String,
                'count': g['count'] as int,
              },
            )
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final List scoresRaw = statistics['scores'] ?? [];
    final Map<String, int> scores = {};
    final sortedScores = List.from(scoresRaw)
      ..sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
    for (final s in sortedScores) {
      scores[s['score'].toString()] = s['count'] as int;
    }

    final List lengthsRaw = statistics['lengths'] ?? [];
    final Map<String, int> lengths = {};
    for (final l in lengthsRaw) {
      lengths[l['length'] as String] = l['count'] as int;
    }

    final Map<String, int> formatDist = {};
    for (final f in (statistics['formats'] ?? [])) {
      formatDist[f['format'] as String] = f['count'] as int;
    }

    final Map<String, int> statusDist = {};
    for (final s in (statistics['statuses'] ?? [])) {
      statusDist[s['status'] as String] = s['count'] as int;
    }

    final Map<String, int> countryDist = {};
    for (final c in (statistics['countries'] ?? [])) {
      countryDist[c['country'] as String] = c['count'] as int;
    }

    final Map<int, int> releaseYearDist = {};
    for (final y in (statistics['releaseYears'] ?? [])) {
      if (y['releaseYear'] != null) {
        releaseYearDist[y['releaseYear'] as int] = y['count'] as int;
      }
    }

    final Map<int, int> startYearDist = {};
    for (final y in (statistics['startYears'] ?? [])) {
      if (y['startYear'] != null) {
        startYearDist[y['startYear'] as int] = y['count'] as int;
      }
    }

    final List<HorizontalStaffItem> voiceActors = [];
    if (isAnime) {
      final List vaRaw = statistics['voiceActors'] ?? [];
      for (final va in vaRaw) {
        final actor = va['voiceActor'];
        if (actor != null) {
          voiceActors.add(
            HorizontalStaffItem(
              id: actor['id'] as int,
              name: actor['name']?['full'] as String? ?? 'Unknown',
              imageUrl: actor['image']?['large'] as String?,
              count: va['count'] as int? ?? 0,
            ),
          );
        }
      }
      voiceActors.sort((a, b) => b.count.compareTo(a.count));
    }

    final List<HorizontalStaffItem> studios = [];
    if (isAnime) {
      final List stRaw = statistics['studios'] ?? [];
      for (final st in stRaw) {
        final studio = st['studio'];
        if (studio != null) {
          studios.add(
            HorizontalStaffItem(
              id: studio['id'] as int,
              name: studio['name'] as String? ?? 'Unknown',
              count: st['count'] as int? ?? 0,
            ),
          );
        }
      }
      studios.sort((a, b) => b.count.compareTo(a.count));
    }

    final List<HorizontalStaffItem> staff = [];
    final List staffRaw = statistics['staff'] ?? [];
    for (final st in staffRaw) {
      final person = st['staff'];
      if (person != null) {
        staff.add(
          HorizontalStaffItem(
            id: person['id'] as int,
            name: person['name']?['full'] as String? ?? 'Unknown',
            imageUrl: person['image']?['large'] as String?,
            count: st['count'] as int? ?? 0,
          ),
        );
      }
    }
    staff.sort((a, b) => b.count.compareTo(a.count));

    final String unit = 'Entries';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatsCard(
            title: isAnime ? 'Anime Statistics' : 'Manga Statistics',
            items: statsItems,
          ),
          if (genres.isNotEmpty)
            GenreOverviewCard(title: 'Genre Overview', genres: genres),
          if (scores.isNotEmpty)
            BarChart(title: 'Score Distribution', data: scores),
          if (lengths.isNotEmpty)
            BarChart(
              title: isAnime ? 'Episode Distribution' : 'Chapter Distribution',
              data: lengths,
            ),
          if (formatDist.isNotEmpty)
            PieChart(title: 'Format Distribution', data: formatDist),
          if (statusDist.isNotEmpty)
            PieChart(title: 'Status Distribution', data: statusDist),
          if (countryDist.isNotEmpty)
            PieChart(title: 'Country Distribution', data: countryDist),
          if (releaseYearDist.isNotEmpty)
            LineChart(
              title: 'Release Year Distribution',
              data: releaseYearDist,
            ),
          if (startYearDist.isNotEmpty)
            LineChart(
              title: isAnime
                  ? 'Watch Year Distribution'
                  : 'Read Year Distribution',
              data: startYearDist,
            ),
          if (isAnime && voiceActors.isNotEmpty)
            HorizontalStaffList(
              title: 'Most Watched Voice Actors',
              items: voiceActors,
              unit: unit,
            ),
          if (isAnime && studios.isNotEmpty)
            HorizontalStaffList(
              title: 'Most Watched Studios',
              items: studios,
              unit: unit,
            ),
          if (staff.isNotEmpty)
            HorizontalStaffList(
              title: isAnime ? 'Most Watched Staff' : 'Most Read Staff',
              items: staff,
              unit: unit,
            ),
        ],
      ),
    );
  }
}
