import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> searchCharacters(
  int page,
  int perPage,
  String searchQuery,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$search: String) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          perPage
          currentPage
          lastPage
          hasNextPage
        }
        characters(search: \$search) {
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
  ''';

  return executeQuery(
    query,
    variables: {"page": page, "perPage": perPage, "search": searchQuery},
    requireAuth: false,
  );
}

Future<Map<String, dynamic>> searchStaff(
  int page,
  int perPage,
  String searchQuery,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$search: String) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          perPage
          currentPage
          lastPage
          hasNextPage
        }
        staff(search: \$search) {
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
  ''';

  return executeQuery(
    query,
    variables: {"page": page, "perPage": perPage, "search": searchQuery},
    requireAuth: false,
  );
}

Future<Map<String, dynamic>> searchStudios(
  int page,
  int perPage,
  String searchQuery,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$search: String) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          perPage
          currentPage
          lastPage
          hasNextPage
        }
        studios(search: \$search) {
          id
          name
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"page": page, "perPage": perPage, "search": searchQuery},
    requireAuth: false,
  );
}

Future<Map<String, dynamic>> searchUsers(
  int page,
  int perPage,
  String searchQuery,
) async {
  const String query = '''
    query (\$page: Int, \$perPage: Int, \$search: String) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          perPage
          currentPage
          lastPage
          hasNextPage
        }
        users(search: \$search) {
          id
          name
          avatar {
            large
          }
        }
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {"page": page, "perPage": perPage, "search": searchQuery},
    requireAuth: false,
  );
}
