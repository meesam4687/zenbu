import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getSimulcasts(
  int epochLower,
  int epochUpper,
) async {
  const String query = '''
    query (\$startStamp: Int, \$endStamp: Int) {
      Page(page: 1, perPage: 100) {
        airingSchedules(sort: TIME, airingAt_greater: \$startStamp, airingAt_lesser: \$endStamp) {
          episode
          media {
            id
            isAdult
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
          airingAt
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"startStamp": epochLower, "endStamp": epochUpper},
  );
}
