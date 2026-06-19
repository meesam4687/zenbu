import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getNotifications(int page, int perPage) async {
  const String query = '''
    query(\$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        notifications (resetNotificationCount: true) {
          ... on AiringNotification {
            id
            type 
            createdAt
            episode
            media {
              id
              type
              title {
                romaji
                english
              }
              coverImage {
                large
              }
            }
          }
          ... on RelatedMediaAdditionNotification {
            id
            type
            createdAt
            media {
              id
              type
              title {
                romaji 
                english
              }
              coverImage {
                large
              }
            }
          }
          ... on MediaDataChangeNotification {
            id
            type
            createdAt
            media {
              id
              type
              title {
                romaji 
                english
              }
              coverImage {
                large
              }
            }
          }
          ... on MediaMergeNotification {
            id
            type
            createdAt
            deletedMediaTitles
            media {
              id
              type
              title {
                romaji 
                english
              }
              coverImage {
                large
              }
            }
          }
        }
      } 
    }
  ''';

  return executeQuery(query, variables: {"page": page, "perPage": perPage});
}
