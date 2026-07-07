import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getMediaLists() async {
  String? token = await TokenStorage.getAccessToken();
  if (token == null) throw 'No authentication token';
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  dynamic userId = decodedToken["sub"];

  const String query = '''
    query (\$type: MediaType!, \$type2: MediaType!, \$userId: Int!) {
      animeList: MediaListCollection(type: \$type, userId: \$userId) {
        lists {
          name
          entries {
            id
            media {
              id
              title { romaji english native }
              coverImage { extraLarge }
              episodes
              status
              bannerImage
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
      }
      mangaList: MediaListCollection(type: \$type2, userId: \$userId) {
        lists {
          name
          entries {
            id
            media {
              id
              title { romaji english native }
              coverImage { extraLarge }
              chapters
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
      }
      favourites: User(id: \$userId) {
        favourites {
          anime {
            nodes {
              id
              title { romaji english native }
              coverImage { extraLarge }
              episodes
              status
              bannerImage
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
          manga {
            nodes {
              id
              title { romaji english native }
              coverImage { extraLarge }
              chapters
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
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"type": "ANIME", "type2": "MANGA", "userId": userId},
  );
}
