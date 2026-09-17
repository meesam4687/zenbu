import 'package:flutter/material.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'stats_card.dart';
import 'genre_overview_card.dart';
import 'bar_chart.dart';
import 'pie_chart.dart';
import 'line_chart.dart';
import 'horizontal_staff_list.dart';
import 'profile_list_button.dart';

class ProfileStatsTab extends StatelessWidget {
  const ProfileStatsTab({
    super.key,
    required this.statistics,
    required this.isAnime,
    required this.userId,
    required this.username,
  });

  final Map<String, dynamic> statistics;
  final bool isAnime;
  final int userId;
  final String username;

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
        StatsItemData(
          label: context.l10n.totalAnime,
          value: '$count',
          icon: Icons.movie,
        ),
        StatsItemData(
          label: context.l10n.episodes,
          value: '$episodes',
          icon: Icons.play_arrow,
        ),
        StatsItemData(
          label: context.l10n.daysWatched,
          value: daysWatched.toStringAsFixed(1),
          icon: Icons.timer,
        ),
        StatsItemData(
          label: context.l10n.daysPlanned,
          value: daysPlanned.toStringAsFixed(1),
          icon: Icons.calendar_today,
        ),
        StatsItemData(
          label: context.l10n.meanScore,
          value: meanScore > 0 ? meanScore.toStringAsFixed(1) : context.l10n.na,
          icon: Icons.star,
        ),
        StatsItemData(
          label: context.l10n.stdDeviation,
          value: stdDev > 0 ? stdDev.toStringAsFixed(1) : context.l10n.na,
          icon: Icons.show_chart,
        ),
      ]);
    } else {
      final chapters = statistics['chaptersRead'] as int? ?? 0;
      final volumes = statistics['volumesRead'] as int? ?? 0;

      statsItems.addAll([
        StatsItemData(
          label: context.l10n.totalManga,
          value: '$count',
          icon: Icons.book,
        ),
        StatsItemData(
          label: context.l10n.chaptersRead,
          value: '$chapters',
          icon: Icons.chrome_reader_mode,
        ),
        StatsItemData(
          label: context.l10n.volumesRead,
          value: '$volumes',
          icon: Icons.library_books,
        ),
        StatsItemData(
          label: context.l10n.plannedManga,
          value: '$planningCount',
          icon: Icons.calendar_today,
        ),
        StatsItemData(
          label: context.l10n.meanScore,
          value: meanScore > 0 ? meanScore.toStringAsFixed(1) : context.l10n.na,
          icon: Icons.star,
        ),
        StatsItemData(
          label: context.l10n.stdDeviation,
          value: stdDev > 0 ? stdDev.toStringAsFixed(1) : context.l10n.na,
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

    final String unit = context.l10n.entries;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatsCard(
            title: isAnime
                ? context.l10n.animeStatistics
                : context.l10n.mangaStatistics,
            items: statsItems,
          ),
          ProfileListButton(
            userId: userId,
            username: username,
            isAnime: isAnime,
          ),
          if (genres.isNotEmpty)
            GenreOverviewCard(
              title: context.l10n.genreOverview,
              genres: genres,
            ),
          if (scores.isNotEmpty)
            BarChart(title: context.l10n.scoreDistribution, data: scores),
          if (lengths.isNotEmpty)
            BarChart(
              title: isAnime
                  ? context.l10n.episodeDistribution
                  : context.l10n.chapterDistribution,
              data: lengths,
            ),
          if (formatDist.isNotEmpty)
            PieChart(title: context.l10n.formatDistribution, data: formatDist),
          if (statusDist.isNotEmpty)
            PieChart(title: context.l10n.statusDistribution, data: statusDist),
          if (countryDist.isNotEmpty)
            PieChart(
              title: context.l10n.countryDistribution,
              data: countryDist,
            ),
          if (releaseYearDist.isNotEmpty)
            LineChart(
              title: context.l10n.releaseYearDistribution,
              data: releaseYearDist,
            ),
          if (startYearDist.isNotEmpty)
            LineChart(
              title: isAnime
                  ? context.l10n.watchYearDistribution
                  : context.l10n.readYearDistribution,
              data: startYearDist,
            ),
          if (isAnime && voiceActors.isNotEmpty)
            HorizontalStaffList(
              title: context.l10n.mostWatchedVoiceActors,
              items: voiceActors,
              unit: unit,
            ),
          if (isAnime && studios.isNotEmpty)
            HorizontalStaffList(
              title: context.l10n.mostWatchedStudios,
              items: studios,
              unit: unit,
            ),
          if (staff.isNotEmpty)
            HorizontalStaffList(
              title: isAnime
                  ? context.l10n.mostWatchedStaff
                  : context.l10n.mostReadStaff,
              items: staff,
              unit: unit,
            ),
        ],
      ),
    );
  }
}
