import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getUserProfile({String? name, int? id}) async {
  const String query = '''
    query (\$name: String, \$id: Int) {
      User(name: \$name, id: \$id) {
        id
        name
        avatar {
          large
        }
        bannerImage
        statistics {
          anime {
            count
            meanScore
            standardDeviation
            minutesWatched
            episodesWatched
            statuses {
              count
              status
            }
            formats {
              count
              format
            }
            countries {
              count
              country
            }
            genres {
              count
              genre
            }
            scores {
              count
              score
            }
            releaseYears {
              count
              releaseYear
            }
            startYears {
              count
              startYear
            }
            voiceActors(limit: 25) {
              count
              voiceActor {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
            studios(limit: 25) {
              count
              studio {
                id
                name
              }
            }
            staff(limit: 25) {
              count
              staff {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
          }
          manga {
            count
            meanScore
            standardDeviation
            chaptersRead
            volumesRead
            statuses {
              count
              status
            }
            formats {
              count
              format
            }
            countries {
              count
              country
            }
            genres {
              count
              genre
            }
            scores {
              count
              score
            }
            releaseYears {
              count
              releaseYear
            }
            startYears {
              count
              startYear
            }
            staff(limit: 25) {
              count
              staff {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
          }
        }
      }
    }
  ''';

  final Map<String, dynamic> variables = {};
  if (name != null) variables['name'] = name;
  if (id != null) variables['id'] = id;

  return executeQuery(query, variables: variables, requireAuth: false);
}
