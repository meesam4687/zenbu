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
              mediaListEntry { status progress }
              status
              bannerImage
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
              mediaListEntry { status progress }
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
              mediaListEntry { status progress }
              status
              bannerImage
            }
          }
          manga {
            nodes {
              id
              title { romaji english native }
              coverImage { extraLarge }
              chapters
              mediaListEntry { status progress }
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
