import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> toggleFavourite({
  int? animeId,
  int? mangaId,
}) async {
  const String query = '''
    mutation (\$animeId: Int, \$mangaId: Int) {
      ToggleFavourite(animeId: \$animeId, mangaId: \$mangaId) {
        anime {
          pageInfo {
            total
          }
        }
        manga {
          pageInfo {
            total
          }
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"animeId": ?animeId, "mangaId": ?mangaId},
  );
}
