import 'package:al_client/secrets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

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
          staff {
            edges {
              id
              role
              node {
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
              id
              role
              node {
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
    String authHeader = 'Bearer $anilistAuthKey';

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
          description 
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

Future<Map<String, dynamic>> getAnimeHomePage(int page, int perPage) async {
  try {
    String authHeader = 'Bearer $anilistAuthKey';
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
    String authHeader = 'Bearer $anilistAuthKey';

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
    String authHeader = 'Bearer $anilistAuthKey';
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
        "variables": {"type": "ANIME", "type2": "MANGA", "userId": 7433884},
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
    String authHeader = 'Bearer $anilistAuthKey';

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
    String authHeader = 'Bearer $anilistAuthKey';
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
    String authHeader = 'Bearer $anilistAuthKey';
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
    String authHeader = 'Bearer $anilistAuthKey';

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
