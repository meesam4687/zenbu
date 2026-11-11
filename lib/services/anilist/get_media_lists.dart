import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:zenbu/services/anilist/anilist_client.dart';

Future<int> _resolveUserId(int? userId) async {
  if (userId != null) return userId;
  String? token = await TokenStorage.getAccessToken();
  if (token == null) throw 'No authentication token';
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  return int.parse(decodedToken["sub"].toString());
}

Future<Map<String, dynamic>> getMediaList({
  required int page,
  required int perPage,
  required String type,
  int? userId,
  String? status,
}) async {
  final targetUserId = await _resolveUserId(userId);
  final mediaType = type.toUpperCase() == "MANGA" ? "MANGA" : "ANIME";
  final hasStatus = status != null && status.isNotEmpty;

  final String query =
      '''
    query (\$page: Int, \$perPage: Int, \$userId: Int!, \$type: MediaType!${hasStatus ? ", \$status: MediaListStatus" : ""}) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          hasNextPage
          total
        }
        mediaList(userId: \$userId, type: \$type${hasStatus ? ", status: \$status" : ""}) {
          id
          status
          score
          progress
          repeat
          startedAt { day month year }
          completedAt { day month year }
          media {
            id
            title { romaji english native }
            coverImage { extraLarge large }
            episodes
            chapters
            status
            bannerImage
          }
        }
      }
    }
  ''';

  final Map<String, dynamic> variables = {
    "page": page,
    "perPage": perPage,
    "userId": targetUserId,
    "type": mediaType,
  };
  if (hasStatus) {
    variables["status"] = status;
  }

  return executeQuery(query, variables: variables);
}

Future<Map<String, dynamic>> getFavourites({
  required int page,
  required int perPage,
  required String type,
  int? userId,
}) async {
  final targetUserId = await _resolveUserId(userId);
  final mediaTypeKey = type.toLowerCase() == "manga" ? "manga" : "anime";

  final String query =
      '''
    query (\$userId: Int!, \$page: Int, \$perPage: Int) {
      User(id: \$userId) {
        favourites {
          $mediaTypeKey(page: \$page, perPage: \$perPage) {
            pageInfo {
              hasNextPage
              total
            }
            nodes {
              id
              title { romaji english native }
              coverImage { extraLarge large }
              episodes
              chapters
              status
              bannerImage
              mediaListEntry {
                id
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
    variables: {"userId": targetUserId, "page": page, "perPage": perPage},
  );
}

Future<Map<String, dynamic>> getMediaListCollection({
  required String type,
  int? userId,
}) async {
  final targetUserId = await _resolveUserId(userId);
  final mediaType = type.toUpperCase() == "MANGA" ? "MANGA" : "ANIME";

  const String query = '''
    query (\$type: MediaType!, \$userId: Int!) {
      MediaListCollection(type: \$type, userId: \$userId) {
        lists {
          name
          entries {
            id
            status
            score
            progress
            repeat
            startedAt { day month year }
            completedAt { day month year }
            media {
              id
              title { romaji english native }
              coverImage { extraLarge large }
              episodes
              chapters
              status
              bannerImage
              mediaListEntry {
                id
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
    variables: {"type": mediaType, "userId": targetUserId},
  );
}
