import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getPopularSeason(int page, int perPage) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$season: MediaSeason, \$seasonYear: Int) {
      list: Page(page: \$page, perPage: \$perPage) {
        media(sort: POPULARITY_DESC, type: ANIME, season: \$season, seasonYear: \$seasonYear) {
          id
          title {
            romaji
            english
            native
          }
          bannerImage
          coverImage {
            large
          }
          episodes
          genres
          nextAiringEpisode {
            episode
          }
          type
          mediaListEntry {
            status
            progress
            score
            repeat
            startedAt { day month year }
            completedAt { day month year }
          }
        }
      }
    }
  ''';

  final String currentSeason = seasonMapping[DateTime.now().month] ?? "WINTER";

  return executeQuery(
    query,
    variables: {
      "page": page,
      "perPage": perPage,
      "season": currentSeason,
      "seasonYear": DateTime.now().year,
    },
  );
}

Future<Map<String, dynamic>> getPopularAllTimeAnime(
  int page,
  int perPage,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int) {
      list: Page(page: \$page, perPage: \$perPage) {
        media(sort: POPULARITY_DESC, type: ANIME) {
          id
          title {
            romaji
            english
            native
          }
          coverImage {
            large
          }
          type
          mediaListEntry {
            status
            progress
            score
            repeat
            startedAt { day month year }
            completedAt { day month year }
          }
        }
      }
    }
  ''';

  return executeQuery(query, variables: {"page": page, "perPage": perPage});
}

Future<Map<String, dynamic>> getPopularAllTimeManga(
  int page,
  int perPage,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int) {
      list: Page(page: \$page, perPage: \$perPage) {
        media(sort: POPULARITY_DESC, type: MANGA) {
          id
          title {
            romaji
            english
            native
          }
          coverImage {
            large
          }
          type
          mediaListEntry {
            status
            progress
            score
            repeat
            startedAt { day month year }
            completedAt { day month year }
          }
        }
      }
    }
  ''';

  return executeQuery(query, variables: {"page": page, "perPage": perPage});
}
