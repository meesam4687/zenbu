import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> updateListItem(
  int mediaId,
  String status,
  int progress,
  Map startDate,
  Map endDate,
  double score,
  int repeat,
) async {
  const String query = '''
    mutation (
      \$mediaId: Int,
      \$status: MediaListStatus,
      \$progress: Int,
      \$startDate: FuzzyDateInput,
      \$endDate: FuzzyDateInput,
      \$score: Float,
      \$repeat: Int
    ) {
      SaveMediaListEntry(
        mediaId: \$mediaId
        status: \$status,
        progress: \$progress,
        startedAt: \$startDate,
        completedAt: \$endDate,
        score: \$score,
        repeat: \$repeat
      ) { 
        id
        status 
        progress 
        startedAt {
          day
          month
          year
        } 
        completedAt {
          day
          month
          year 
        }
        score
        repeat
      }
    }
  ''';

  return executeQuery(
    query,
    variables: {
      "mediaId": mediaId,
      "status": status,
      "progress": progress,
      "startDate": startDate,
      "endDate": endDate,
      "score": score,
      "repeat": repeat,
    },
  );
}
