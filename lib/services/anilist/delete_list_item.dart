import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> deleteListItem(int entryId) async {
  const String query = '''
    mutation (\$id: Int) {
      DeleteMediaListEntry(id: \$id) {
        deleted
      }
    }
  ''';

  return executeQuery(query, variables: {"id": entryId});
}
