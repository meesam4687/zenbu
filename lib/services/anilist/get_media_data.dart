import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> getAnimeData(int id) async {
  const String query = '''
    query(\$id: Int) {
      Media(id: \$id) {
        idMal
        isFavourite
        title {
          english
          native
          romaji
        } 
        format
        coverImage {
          extraLarge
        }
        bannerImage
        status
        episodes
        streamingEpisodes {
          title
          thumbnail
        }
        startDate {
          day
          month
          year
        }
        endDate {
          day
          month
          year
        }
        season
        seasonYear
        description
        duration
        countryOfOrigin
        source
        genres
        meanScore
        studios {
          nodes {
            name
          }
        }
        staff {
          edges {
            role
            node {
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
        recommendations {
          edges {
            node {
              media: mediaRecommendation {
                id
                title {
                  romaji
                }
                coverImage {
                  extraLarge
                } 
                type
                mediaListEntry {
                  status
                  progress
                  score
                  repeat
                  startedAt { day month year }
                  completedAt { day month year }
                }
              }
            }
          }
        } 
        tags {
          name
        }
        relations {
          edges {
            relationType(version: 2)
              node {
                id
                type
                title {
                  romaji
                }
                coverImage {
                  extraLarge
                }
                mediaListEntry {
                  status
                  progress
                  score
                  repeat
                  startedAt { day month year }
                  completedAt { day month year }
                }
              }
          }
        }
        characters(sort: [ROLE]) {
          characters: edges {
            role
            node {
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
        mediaListEntry {
          id
          mediaId
          progress
          status
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
    }
  ''';

  return executeQuery(query, variables: {"id": id});
}

Future<Map<String, dynamic>> getMangaData(int id) async {
  const String query = '''
    query(\$id: Int) {
      Media(id: \$id) {
        isFavourite
        title {
          english
          native
          romaji
        } 
        format
        coverImage {
          extraLarge
        }
        bannerImage
        status
        chapters
        startDate {
          day
          month
          year
        }
        endDate {
          day
          month
          year
        }
        season
        seasonYear
        description
        duration
        countryOfOrigin
        source
        genres
        meanScore
        staff {
          edges {
            role
            node {
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
        recommendations {
          edges {
            node {
              media: mediaRecommendation {
                id
                title {
                  romaji
                }
                coverImage {
                  extraLarge
                } 
                type
              }
            }
          }
        } 
        tags {
          name
        }
        relations {
          edges {
            relationType(version: 2)
              node {
                id
                type
                title {
                  romaji
                }
                coverImage {
                  extraLarge
                }
              }
          }
        }
        characters(sort: [ROLE]) {
          characters: edges {
            role
            node {
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
        mediaListEntry {
          id
          mediaId
          progress
          status
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
    }
  ''';

  return executeQuery(query, variables: {"id": id});
}
