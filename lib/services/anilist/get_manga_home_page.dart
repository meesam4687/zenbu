import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getMangaHomePage(int page, int perPage) async {
  const String query = '''
    query(\$page: Int, \$perPage: Int) {
      trending: Page(page: \$page, perPage: \$perPage) {
        media(sort: TRENDING_DESC, type: MANGA) {
          id
          title {
            romaji
            english
            native
          }
          coverImage {
            large
          }
          genres
          bannerImage
          chapters
          volumes
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
      allTimePopular: Page(page: \$page, perPage: \$perPage) {
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
      highestRated: Page(page: \$page, perPage: \$perPage) {
        media(sort: SCORE_DESC, type: MANGA) {
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
