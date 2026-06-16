import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getAnimeHomePage(int page, int perPage) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$season: MediaSeason, \$seasonYear: Int, \$nextSeason: MediaSeason) {
      trending: Page(page: \$page, perPage: \$perPage) {
        media(sort: TRENDING_DESC, type: ANIME) {
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
        }
      }
      popularSeason: Page(page: \$page, perPage: \$perPage) {
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
        }
      }
      upcoming: Page(page: \$page, perPage: \$perPage) {
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
        }
      }
      allTimePopular: Page(page: \$page, perPage: \$perPage) {
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
        }
      }
      highestRated: Page(page: \$page, perPage: \$perPage) {
        media(sort: SCORE_DESC, type: ANIME) {
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
        }
      }
    }
  ''';

  final String currentSeason = seasonMapping[DateTime.now().month] ?? "WINTER";
  final String nextSeasonVal = getNextSeason(currentSeason);

  return executeQuery(
    query,
    variables: {
      "page": page,
      "perPage": perPage,
      "season": currentSeason,
      "nextSeason": nextSeasonVal,
      "seasonYear": DateTime.now().year,
    },
  );
}
