import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getTrendingAnime(int page, int perPage) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int) {
      list: Page(page: \$page, perPage: \$perPage) {
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

Future<Map<String, dynamic>> getTrendingManga(int page, int perPage) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int) {
      list: Page(page: \$page, perPage: \$perPage) {
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
    }
  ''';

  return executeQuery(query, variables: {"page": page, "perPage": perPage});
}
