import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getCharacterData(int id) async {
  const String query = '''
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

  return executeQuery(query, variables: {"id": id});
}
