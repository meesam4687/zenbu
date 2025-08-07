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
                status
                bannerImage
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
                bannerImage
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
        "variables": {"type": "ANIME", "type2": "MANGA", "userId": 7433884},
      }),
    );

    final data = jsonDecode(res.body);
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getAnimeData(int id) async {
  try {
    String authHeader = 'Bearer $anilistAuthKey';

    String query = '''
      query(\$id: Int) {
        Media(id: \$id) {
          title {
            english
            native
            romaji
          } 
          format
          coverImage {
            extraLarge
          }
          bannerImage
          status
          episodes
          startDate {
            day
            month
            year
          }
          endDate {
            day
            month
            year
          }
          season
          seasonYear
          description
          duration
          countryOfOrigin
          source
          genres
          meanScore
          studios {
            nodes {
              name
            }
          }
          tags {
            name
          }
          relations {
            edges {
              relationType(version: 2)
                node {
                  id
                  type
                  title
                  {
                    romaji
                  }
                  coverImage {
                    extraLarge
                  }
                }
            }
          }
          characters(sort: [ROLE]) {
            characters: edges {
              role
              node {
                id
                name { 
                  full
                  native
                }
                image {
                  large
                } 
              }
            }
          }
          mediaListEntry {
            progress
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
        "variables": {"id": id},
      }),
    );

    final data = jsonDecode(res.body);
    return data;
  } catch (e) {
    throw e.toString();
  }
}
