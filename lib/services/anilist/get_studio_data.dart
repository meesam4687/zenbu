import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getStudioData({
  required int id,
  required int page,
  required int perPage,
}) async {
  const String query = '''
    query (\$id: Int, \$page: Int, \$perPage: Int) {
      Studio(id: \$id) {
        id
        name
        media(page: \$page, perPage: \$perPage, sort: POPULARITY_DESC) {
          pageInfo {
            total
            perPage
            currentPage
            lastPage
            hasNextPage
          }
          nodes {
            id
            title {
              userPreferred
            }
            coverImage {
              large
            }
            format
            seasonYear
          }
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"id": id, "page": page, "perPage": perPage},
    requireAuth: false,
  );
}
