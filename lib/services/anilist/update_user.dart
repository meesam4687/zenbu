import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> updateUserTitleLanguage(String language) async {
  const String mutation = '''
    mutation (\$titleLanguage: UserTitleLanguage) {
      UpdateUser(titleLanguage: \$titleLanguage) {
        id
        options {
          titleLanguage
        }
      }
    }
  ''';

  return executeQuery(mutation, variables: {'titleLanguage': language});
}

Future<Map<String, dynamic>> updateUserDisplayAdultContent(bool displayAdultContent) async {
  const String mutation = '''
    mutation (\$displayAdultContent: Boolean) {
      UpdateUser(displayAdultContent: \$displayAdultContent) {
        id
        options {
          displayAdultContent
        }
      }
    }
  ''';

  return executeQuery(mutation, variables: {'displayAdultContent': displayAdultContent});
}

