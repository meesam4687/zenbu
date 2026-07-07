import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getUpcomingAnime(int page, int perPage) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$nextSeason: MediaSeason) {
      list: Page(page: \$page, perPage: \$perPage) {
        media(status: NOT_YET_RELEASED, sort: POPULARITY_DESC, type: ANIME, season: \$nextSeason) {
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

  final String currentSeason = seasonMapping[DateTime.now().month] ?? "WINTER";
  final String nextSeasonVal = getNextSeason(currentSeason);

  return executeQuery(
    query,
    variables: {"page": page, "perPage": perPage, "nextSeason": nextSeasonVal},
  );
}
