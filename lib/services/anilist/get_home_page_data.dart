import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getHomePageData() async {
  String? token = await TokenStorage.getAccessToken();
  if (token == null) throw 'No authentication token';
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  dynamic userId = decodedToken["sub"];

  String query = '''
    query (\$type: MediaType!, \$type2: MediaType!, \$userId: Int!) {
      Viewer {
        id
        name
        avatar { large }
        unreadNotificationCount
        options {
          titleLanguage
          displayAdultContent
        }
      }
      animeList: MediaListCollection(type: \$type, userId: \$userId, status_in: [CURRENT, REPEATING], sort: UPDATED_TIME_DESC) {
        lists {
          name
          entries {
            id
            media {
              id
              title { romaji english native }
              coverImage { extraLarge }
              episodes
              mediaListEntry { status progress }
              status
              bannerImage
              mediaListEntry {
                id
                progress
                status
                startedAt { 
                  day 
                  month 
                  year 
                } 
                completedAt { 
                  day 
                  month 
                  year 
                } 
                score 
                repeat
              }
            }
          }
        }
      }
      mangaList: MediaListCollection(type: \$type2, userId: \$userId, status_in: [CURRENT, REPEATING], sort: UPDATED_TIME_DESC) {
        lists {
          name
          entries {
            id
            media {
              id
              title { romaji english native }
              coverImage { extraLarge }
              chapters
              mediaListEntry { status progress }
              bannerImage
              mediaListEntry {
                id
                progress
                status
                startedAt { 
                  day 
                  month 
                  year 
                } 
                completedAt { 
                  day 
                  month 
                  year 
                } 
                score 
                repeat
              }
            }
          }
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"type": "ANIME", "type2": "MANGA", "userId": userId},
  );
}
