import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getStaffData(int id) async {
  const String query = '''
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

  return executeQuery(query, variables: {"id": id});
}
