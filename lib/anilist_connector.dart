import 'package:al_client/secrets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> getHomePageData() async {
  try {
    String authHeader = 'Bearer $anilistAuthKey';

    String query = '''
      query (\$type: MediaType!, \$type2: MediaType!, \$userId: Int!) {
        Viewer {
          id
          name
          avatar { large }
        }
        animeList: MediaListCollection(type: \$type, userId: \$userId, status_in: CURRENT) {
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
              }
            }
          }
        }
        mangaList: MediaListCollection(type: \$type2, userId: \$userId, status_in: CURRENT) {
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
      }
    ''';

    final res = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {"type": "ANIME", "type2": "MANGA", "userId": 5656469},
      }),
    );

    final data = jsonDecode(res.body);
    return data;
  } catch (e) {
    throw e.toString();
  }
}
