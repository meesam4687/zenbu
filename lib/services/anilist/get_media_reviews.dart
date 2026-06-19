import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getMediaReviews(
  int id,
  int page,
  int perPage,
) async {
  const String query = '''
    query (\$id: Int, \$page: Int, \$perPage: Int) {
      Media(id: \$id) {
        id 
        reviews(page: \$page, perPage: \$perPage) {
          nodes { 
            id 
            mediaId 
            summary 
            body 
            score 
          } 
        }
      } 
    }
  ''';

  return executeQuery(
    query,
    variables: {"id": id, "page": page, "perPage": perPage},
  );
}
