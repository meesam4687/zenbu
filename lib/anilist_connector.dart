import 'package:zenbu/authentication_token_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

Future<Map<String, dynamic>> getHomePageData() async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String userId = decodedToken["sub"];

    String query = '''
      query (\$type: MediaType!, \$type2: MediaType!, \$userId: Int!) {
        Viewer {
          id
          name
          avatar { large }
          unreadNotificationCount
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

    final res = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {"type": "ANIME", "type2": "MANGA", "userId": userId},
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getAnimeData(int id) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

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
          streamingEpisodes {
            title
            thumbnail
          }
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
          staff {
            edges {
              role
              node {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
          }
          recommendations {
            edges {
              node {
                media: mediaRecommendation {
                  id
                  title {
                    romaji
                  }
                  coverImage {
                    extraLarge
                  } 
                  type
                }
              }
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
            id
            mediaId
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
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getMangaData(int id) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

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
          chapters
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
          staff {
            edges {
              role
              node {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
          }
          recommendations {
            edges {
              node {
                media: mediaRecommendation {
                  id
                  title {
                    romaji
                  }
                  coverImage {
                    extraLarge
                  } 
                  type
                }
              }
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
            id
            mediaId
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
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getCharacterData(int id) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query(\$id: Int) {
        Character(id: \$id) {
          name { 
            full
            native
            alternative
          }
          image {
            large
          } 
          gender 
          description(asHtml: false) 
          media { 
            nodes { 
              id 
              title { 
                romaji 
              } 
              type
              coverImage {
                extraLarge
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
        "variables": {"id": id},
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getStaffData(int id) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query(\$id: Int) {
        Staff(id: \$id) {
          name { 
            full
            native
            alternative
          }
          image {
            large
          } 
          gender 
          description(asHtml: false) 
          staffMedia { 
            nodes { 
              id 
              title { 
                romaji 
              } 
              type
              coverImage {
                extraLarge
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
        "variables": {"id": id},
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getAnimeHomePage(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    List<String> seasonArray = ["WINTER", "SPRING", "SUMMER", "FALL"];
    Map<int, String> seasonMapping = {
      1: "WINTER",
      2: "WINTER",
      3: "WINTER",
      4: "SPRING",
      5: "SPRING",
      6: "SPRING",
      7: "SUMMER",
      8: "SUMMER",
      9: "SUMMER",
      10: "FALL",
      11: "FALL",
      12: "FALL",
    };

    String query = '''
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

    final res = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {
          "page": page,
          "perPage": perPage,
          "season": seasonMapping[DateTime.now().month],
          "nextSeason":
              seasonArray[(seasonArray.indexOf(
                        seasonMapping[DateTime.now().month].toString(),
                      ) !=
                      3)
                  ? seasonArray.indexOf(
                          seasonMapping[DateTime.now().month].toString(),
                        ) +
                        1
                  : 0],
          "seasonYear": DateTime.now().year,
        },
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getMangaHomePage(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getMediaLists() async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String userId = decodedToken["sub"];
    String query = '''
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
        "variables": {"type": "ANIME", "type2": "MANGA", "userId": userId},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getTrendingAnime(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getPopularSeason(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    Map<int, String> seasonMapping = {
      1: "WINTER",
      2: "WINTER",
      3: "WINTER",
      4: "SPRING",
      5: "SPRING",
      6: "SPRING",
      7: "SUMMER",
      8: "SUMMER",
      9: "SUMMER",
      10: "FALL",
      11: "FALL",
      12: "FALL",
    };

    String query = '''
      query (\$page: Int, \$perPage: Int, \$season: MediaSeason, \$seasonYear: Int) {
        list: Page(page: \$page, perPage: \$perPage) {
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
        "variables": {
          "page": page,
          "perPage": perPage,
          "season": seasonMapping[DateTime.now().month],
          "seasonYear": DateTime.now().year,
        },
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getUpcomingAnime(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    List<String> seasonArray = ["WINTER", "SPRING", "SUMMER", "FALL"];
    Map<int, String> seasonMapping = {
      1: "WINTER",
      2: "WINTER",
      3: "WINTER",
      4: "SPRING",
      5: "SPRING",
      6: "SPRING",
      7: "SUMMER",
      8: "SUMMER",
      9: "SUMMER",
      10: "FALL",
      11: "FALL",
      12: "FALL",
    };
    String query = '''
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
        "variables": {
          "page": page,
          "perPage": perPage,
          "nextSeason":
              seasonArray[(seasonArray.indexOf(
                        seasonMapping[DateTime.now().month].toString(),
                      ) !=
                      3)
                  ? seasonArray.indexOf(
                          seasonMapping[DateTime.now().month].toString(),
                        ) +
                        1
                  : 0],
        },
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getPopularAllTimeAnime(
  int page,
  int perPage,
) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query (\$page: Int, \$perPage: Int) {
        list: Page(page: \$page, perPage: \$perPage) {
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getHighestRatedAnime(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query (\$page: Int, \$perPage: Int) {
        list: Page(page: \$page, perPage: \$perPage) {
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

    final res = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getTrendingManga(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getHighestRatedManga(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query (\$page: Int, \$perPage: Int) {
        list: Page(page: \$page, perPage: \$perPage) {
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getPopularAllTimeManga(
  int page,
  int perPage,
) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query (\$page: Int, \$perPage: Int) {
        list: Page(page: \$page, perPage: \$perPage) {
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> searchAnime(
  int page,
  int perPage,
  String? searchQuery,
  List? genreIn,
  List? tagIn,
  String? season,
  int? seasonYear,
  String? format,
  String? status,
  String? countryOfOrigin,
  String? mediaSource,
) async {
  Map vars = {"page": page, "perPage": perPage};
  if (searchQuery != null) vars["search"] = searchQuery;
  if (genreIn != null && genreIn.isNotEmpty) vars["genreIn"] = genreIn;
  if (tagIn != null && tagIn.isNotEmpty) vars["tagIn"] = tagIn;
  if (season != null && season.isNotEmpty) vars["season"] = season;
  if (seasonYear != null && seasonYear != 0) vars["seasonYear"] = seasonYear;
  if (format != null && format.isNotEmpty) vars["format"] = format;
  if (status != null && status.isNotEmpty) vars["status"] = status;
  if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
    vars["countryOfOrigin"] = countryOfOrigin;
  }
  if (mediaSource != null && mediaSource.isNotEmpty) {
    vars["source"] = mediaSource;
  }
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    String query =
        '''
      query (
      \$page: Int,
      \$perPage: Int${vars.containsKey("search") ? ", \$search: String" : ""}${vars.containsKey("genreIn") ? ", \$genreIn: [String]" : ""}${vars.containsKey("tagIn") ? ", \$tagIn: [String]" : ""}${vars.containsKey("season") ? ", \$season: MediaSeason" : ""}${vars.containsKey("seasonYear") ? ", \$seasonYear: Int" : ""}${vars.containsKey("format") ? ", \$format: MediaFormat" : ""}${vars.containsKey("status") ? ", \$status: MediaStatus" : ""}${vars.containsKey("countryOfOrigin") ? ", \$countryOfOrigin: CountryCode" : ""}${vars.containsKey("source") ? ", \$source: MediaSource" : ""}
      ) {
        Page(page: \$page, perPage: \$perPage) { 
        media(
          type: ANIME,
          ${vars.containsKey("search") ? "search: \$search," : ""}
          ${vars.containsKey("genreIn") ? "genre_in: \$genreIn," : ""}
          ${vars.containsKey("tagIn") ? "tag_in: \$tagIn," : ""}
          ${vars.containsKey("season") ? "season: \$season," : ""}
          ${vars.containsKey("seasonYear") ? "seasonYear: \$seasonYear," : ""}
          ${vars.containsKey("format") ? "format: \$format," : ""}
          ${vars.containsKey("status") ? "status: \$status," : ""}
          ${vars.containsKey("countryOfOrigin") ? "countryOfOrigin: \$countryOfOrigin," : ""}
          ${vars.containsKey("source") ? "source: \$source," : ""}
          sort: POPULARITY_DESC,
        ) {
          id 
          title { romaji english native }
          coverImage { large } 
          type 
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
      body: jsonEncode({"query": query, "variables": vars}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> searchManga(
  int page,
  int perPage,
  String? searchQuery,
  List? genreIn,
  List? tagIn,
  int? seasonYear,
  String? format,
  String? status,
  String? countryOfOrigin,
  String? mediaSource,
) async {
  Map vars = {"page": page, "perPage": perPage};
  if (searchQuery != null) vars["search"] = searchQuery;
  if (genreIn != null && genreIn.isNotEmpty) vars["genreIn"] = genreIn;
  if (tagIn != null && tagIn.isNotEmpty) vars["tagIn"] = tagIn;
  if (seasonYear != null && seasonYear != 0) {
    vars["startDate_greater"] = "${seasonYear}0000";
  }
  if (seasonYear != null && seasonYear != 0) {
    vars["startDate_lesser"] = "${seasonYear}9999";
  }
  if (format != null && format.isNotEmpty) vars["format"] = format;
  if (status != null && status.isNotEmpty) vars["status"] = status;
  if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
    vars["countryOfOrigin"] = countryOfOrigin;
  }
  if (mediaSource != null && mediaSource.isNotEmpty) {
    vars["source"] = mediaSource;
  }
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    String query =
        '''
      query (
      \$page: Int,
      \$perPage: Int${vars.containsKey("search") ? ", \$search: String" : ""}${vars.containsKey("genreIn") ? ", \$genreIn: [String]" : ""}${vars.containsKey("tagIn") ? ", \$tagIn: [String]" : ""}${vars.containsKey("startDate_greater") ? ", \$startDate_greater: FuzzyDateInt, \$startDate_lesser: FuzzyDateInt" : ""}${vars.containsKey("format") ? ", \$format: MediaFormat" : ""}${vars.containsKey("status") ? ", \$status: MediaStatus" : ""}${vars.containsKey("countryOfOrigin") ? ", \$countryOfOrigin: CountryCode" : ""}${vars.containsKey("source") ? ", \$source: MediaSource" : ""}
      ) {
        Page(page: \$page, perPage: \$perPage) { 
        media(
          type: MANGA,
          ${vars.containsKey("search") ? "search: \$search," : ""}
          ${vars.containsKey("genreIn") ? "genre_in: \$genreIn," : ""}
          ${vars.containsKey("tagIn") ? "tag_in: \$tagIn," : ""}
          ${vars.containsKey("startDate_greater") ? "startDate_greater: \$startDate_greater, startDate_lesser: \$startDate_lesser," : ""}
          ${vars.containsKey("format") ? "format: \$format," : ""}
          ${vars.containsKey("status") ? "status: \$status," : ""}
          ${vars.containsKey("countryOfOrigin") ? "countryOfOrigin: \$countryOfOrigin," : ""}
          ${vars.containsKey("source") ? "source: \$source," : ""}
          sort: POPULARITY_DESC,
        ) {
          id 
          title { romaji english native }
          coverImage { large } 
          type 
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
      body: jsonEncode({"query": query, "variables": vars}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> updateListItem(
  int mediaId,
  String status,
  int progress,
  Map startDate,
  Map endDate,
  double score,
  int repeat,
) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';
    String query = '''
      mutation (
        \$mediaId: Int,
        \$status: MediaListStatus,
        \$progress: Int,
        \$startDate: FuzzyDateInput,
        \$endDate: FuzzyDateInput,
        \$score: Float,
        \$repeat: Int
      ) {
          SaveMediaListEntry(
            mediaId: \$mediaId
            status: \$status,
            progress: \$progress,
            startedAt: \$startDate,
            completedAt: \$endDate,
            score: \$score,
            repeat: \$repeat
          ) { 
              id
              status 
              progress 
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
      ''';

    final res = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {
          "mediaId": mediaId,
          "status": status,
          "progress": progress,
          "startDate": startDate,
          "endDate": endDate,
          "score": score,
          "repeat": repeat,
        },
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getNotifications(int page, int perPage) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query(\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          notifications (resetNotificationCount: true) {
            ... on AiringNotification {
              id
              type 
              createdAt
              episode
              media {
                id
                type
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
              }
            }
            ... on RelatedMediaAdditionNotification {
              id
              type
              createdAt
              media {
                id
                type
                title {
                  romaji 
                  english
                }
                coverImage {
                  large
                }
              }
            }
            ... on MediaDataChangeNotification {
              id
              type
              createdAt
              media {
                id
                type
                title {
                  romaji 
                  english
                }
                coverImage {
                  large
                }
              }
            }
            ... on MediaMergeNotification {
              id
              type
              createdAt
              deletedMediaTitles
              media {
                id
                type
                title {
                  romaji 
                  english
                }
                coverImage {
                  large
                }
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
        "variables": {"page": page, "perPage": perPage},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}

Future<Map<String, dynamic>> getSimulcasts(
  int epochLower,
  int epochUpper,
) async {
  try {
    String? token = await TokenStorage.getAccessToken();
    if (token == null) throw 'No authentication token';

    String authHeader = 'Bearer $token';

    String query = '''
      query (\$startStamp: Int, \$endStamp: Int) {
        Page(page: 1, perPage: 100) {
          airingSchedules(sort: TIME, airingAt_greater: \$startStamp, airingAt_lesser: \$endStamp) {
            episode
            media {
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
            airingAt
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
        "variables": {"startStamp": epochLower, "endStamp": epochUpper},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }
    return data;
  } catch (e) {
    throw e.toString();
  }
}
