import 'package:zenbu/services/anilist/anilist_client.dart';

Future<Map<String, dynamic>> searchAnime(
  int page,
  int perPage,
  String? searchQuery,
  List? genreIn,
  List? tagIn,
  String? season,
  int? seasonYear,
  String? format,
  String? status,
  String? countryOfOrigin,
  String? mediaSource,
) async {
  Map<String, dynamic> vars = {"page": page, "perPage": perPage};
  if (searchQuery != null) vars["search"] = searchQuery;
  if (genreIn != null && genreIn.isNotEmpty) vars["genreIn"] = genreIn;
  if (tagIn != null && tagIn.isNotEmpty) vars["tagIn"] = tagIn;
  if (season != null && season.isNotEmpty) vars["season"] = season;
  if (seasonYear != null && seasonYear != 0) vars["seasonYear"] = seasonYear;
  if (format != null && format.isNotEmpty) vars["format"] = format;
  if (status != null && status.isNotEmpty) vars["status"] = status;
  if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
    vars["countryOfOrigin"] = countryOfOrigin;
  }
  if (mediaSource != null && mediaSource.isNotEmpty) {
    vars["source"] = mediaSource;
  }

  String query = '''
    query (
      \$page: Int,
      \$perPage: Int${vars.containsKey("search") ? ", \$search: String" : ""}${vars.containsKey("genreIn") ? ", \$genreIn: [String]" : ""}${vars.containsKey("tagIn") ? ", \$tagIn: [String]" : ""}${vars.containsKey("season") ? ", \$season: MediaSeason" : ""}${vars.containsKey("seasonYear") ? ", \$seasonYear: Int" : ""}${vars.containsKey("format") ? ", \$format: MediaFormat" : ""}${vars.containsKey("status") ? ", \$status: MediaStatus" : ""}${vars.containsKey("countryOfOrigin") ? ", \$countryOfOrigin: CountryCode" : ""}${vars.containsKey("source") ? ", \$source: MediaSource" : ""}
    ) {
      Page(page: \$page, perPage: \$perPage) { 
        media(
          type: ANIME,
          ${vars.containsKey("search") ? "search: \$search," : ""}
          ${vars.containsKey("genreIn") ? "genre_in: \$genreIn," : ""}
          ${vars.containsKey("tagIn") ? "tag_in: \$tagIn," : ""}
          ${vars.containsKey("season") ? "season: \$season," : ""}
          ${vars.containsKey("seasonYear") ? "seasonYear: \$seasonYear," : ""}
          ${vars.containsKey("format") ? "format: \$format," : ""}
          ${vars.containsKey("status") ? "status: \$status," : ""}
          ${vars.containsKey("countryOfOrigin") ? "countryOfOrigin: \$countryOfOrigin," : ""}
          ${vars.containsKey("source") ? "source: \$source," : ""}
          sort: POPULARITY_DESC,
        ) {
          id 
          title { romaji english native }
          coverImage { large } 
          type 
        }
      } 
    }
  ''';

  return executeQuery(query, variables: vars);
}

Future<Map<String, dynamic>> searchManga(
  int page,
  int perPage,
  String? searchQuery,
  List? genreIn,
  List? tagIn,
  int? seasonYear,
  String? format,
  String? status,
  String? countryOfOrigin,
  String? mediaSource,
) async {
  Map<String, dynamic> vars = {"page": page, "perPage": perPage};
  if (searchQuery != null) vars["search"] = searchQuery;
  if (genreIn != null && genreIn.isNotEmpty) vars["genreIn"] = genreIn;
  if (tagIn != null && tagIn.isNotEmpty) vars["tagIn"] = tagIn;
  if (seasonYear != null && seasonYear != 0) {
    vars["startDate_greater"] = "${seasonYear}0000";
    vars["startDate_lesser"] = "${seasonYear}9999";
  }
  if (format != null && format.isNotEmpty) vars["format"] = format;
  if (status != null && status.isNotEmpty) vars["status"] = status;
  if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
    vars["countryOfOrigin"] = countryOfOrigin;
  }
  if (mediaSource != null && mediaSource.isNotEmpty) {
    vars["source"] = mediaSource;
  }

  String query = '''
    query (
      \$page: Int,
      \$perPage: Int${vars.containsKey("search") ? ", \$search: String" : ""}${vars.containsKey("genreIn") ? ", \$genreIn: [String]" : ""}${vars.containsKey("tagIn") ? ", \$tagIn: [String]" : ""}${vars.containsKey("startDate_greater") ? ", \$startDate_greater: FuzzyDateInt, \$startDate_lesser: FuzzyDateInt" : ""}${vars.containsKey("format") ? ", \$format: MediaFormat" : ""}${vars.containsKey("status") ? ", \$status: MediaStatus" : ""}${vars.containsKey("countryOfOrigin") ? ", \$countryOfOrigin: CountryCode" : ""}${vars.containsKey("source") ? ", \$source: MediaSource" : ""}
    ) {
      Page(page: \$page, perPage: \$perPage) { 
        media(
          type: MANGA,
          ${vars.containsKey("search") ? "search: \$search," : ""}
          ${vars.containsKey("genreIn") ? "genre_in: \$genreIn," : ""}
          ${vars.containsKey("tagIn") ? "tag_in: \$tagIn," : ""}
          ${vars.containsKey("startDate_greater") ? "startDate_greater: \$startDate_greater, startDate_lesser: \$startDate_lesser," : ""}
          ${vars.containsKey("format") ? "format: \$format," : ""}
          ${vars.containsKey("status") ? "status: \$status," : ""}
          ${vars.containsKey("countryOfOrigin") ? "countryOfOrigin: \$countryOfOrigin," : ""}
          ${vars.containsKey("source") ? "source: \$source," : ""}
          sort: POPULARITY_DESC,
        ) {
          id 
          title { romaji english native }
          coverImage { large } 
          type 
        }
      } 
    }
  ''';

  return executeQuery(query, variables: vars);
}
