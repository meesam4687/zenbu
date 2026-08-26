import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static double? parseEpisodeNumber(String url, String name) {
    try {
      final parsed = jsonDecode(url);
      if (parsed is Map && parsed.containsKey('num')) {
        return double.tryParse(parsed['num'].toString());
      }
    } catch (_) {}

    final matchExplicit = RegExp(
      r'\b(?:episode|ep|chapter|chap|ch)[\s._-]*(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    ).firstMatch(name);
    if (matchExplicit != null) return double.tryParse(matchExplicit.group(1)!);

    if (url.contains('/')) {
      final parts = url.split('/');
      final last = parts.last;
      final matchUrl = RegExp(
        r'\b(?:episode|ep|chapter|chap|ch)[\s._-]*(\d+(?:\.\d+)?)\b',
        caseSensitive: false,
      ).firstMatch(last);
      if (matchUrl != null) return double.tryParse(matchUrl.group(1)!);

      final parsed = double.tryParse(last);
      if (parsed != null) return parsed;
    }

    if (url.contains('|')) {
      final parts = url.split('|');
      final parsed = double.tryParse(parts.last);
      if (parsed != null) return parsed;
    }

    final matchShorthand = RegExp(
      r'(?:\b[EeCc]|\b#)\s*(\d+(?:\.\d+)?)\b',
    ).firstMatch(name);
    if (matchShorthand != null) {
      return double.tryParse(matchShorthand.group(1)!);
    }

    final matchDash = RegExp(r'-\s*(\d+(?:\.\d+)?)\b').firstMatch(name);
    if (matchDash != null) {
      return double.tryParse(matchDash.group(1)!);
    }

    return null;
  }

  static String _getMangaKeyPrefix(int mediaId, String url) {
    return 'manga_progress_${mediaId}_url_$url';
  }

  static String _getAnimeKeyPrefix(int mediaId, String url) {
    return 'anime_progress_${mediaId}_url_$url';
  }

  static Future<void> saveMangaProgress({
    required int mediaId,
    required String chapterUrl,
    required String chapterName,
    required int pagesRead,
    required int totalPages,
  }) async {
    if (totalPages <= 0) return;
    final prefs = await SharedPreferences.getInstance();

    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl);
    final keyPage = '${prefix}_page';
    final keyTotal = '${prefix}_total';
    final keyRead = '${prefix}_read';

    await prefs.setInt(keyPage, pagesRead);
    await prefs.setInt(keyTotal, totalPages);

    if (pagesRead >= totalPages) {
      await prefs.setBool(keyRead, true);
    }
  }

  static Future<bool> isMangaChapterRead({
    required int mediaId,
    required String chapterUrl,
    required String chapterName,
    required int anilistProgress,
    int? chapterIndex,
  }) async {
    if (chapterIndex != null && chapterIndex <= anilistProgress) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl);
    final keyRead = '${prefix}_read';
    return prefs.getBool(keyRead) ?? false;
  }

  static Future<Map<String, int>?> getMangaChapterProgress({
    required int mediaId,
    required String chapterUrl,
    required String chapterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl);
    final keyPage = '${prefix}_page';
    final keyTotal = '${prefix}_total';

    final pagesRead = prefs.getInt(keyPage);
    final totalPages = prefs.getInt(keyTotal);

    if (pagesRead != null && totalPages != null && totalPages > 0) {
      return {'pagesRead': pagesRead, 'totalPages': totalPages};
    }
    return null;
  }

  static Future<void> saveAnimeProgress({
    required int mediaId,
    required String episodeUrl,
    required String episodeName,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    if (durationSeconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();

    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl);
    final keyPos = '${prefix}_pos';
    final keyDur = '${prefix}_dur';
    final keyWatched = '${prefix}_watched';

    await prefs.setInt(keyPos, positionSeconds);
    await prefs.setInt(keyDur, durationSeconds);

    final isWatched =
        positionSeconds >= durationSeconds * 0.9 ||
        (durationSeconds - positionSeconds) <= 30;
    if (isWatched) {
      await prefs.setBool(keyWatched, true);
    }
  }

  static Future<bool> isAnimeEpisodeWatched({
    required int mediaId,
    required String episodeUrl,
    required String episodeName,
    required int anilistProgress,
    int? episodeIndex,
  }) async {
    if (episodeIndex != null && episodeIndex <= anilistProgress) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl);
    final keyWatched = '${prefix}_watched';
    return prefs.getBool(keyWatched) ?? false;
  }

  static Future<double> getAnimeEpisodeProgressRatio({
    required int mediaId,
    required String episodeUrl,
    required String episodeName,
    required int anilistProgress,
    int? episodeIndex,
  }) async {
    final watched = await isAnimeEpisodeWatched(
      mediaId: mediaId,
      episodeUrl: episodeUrl,
      episodeName: episodeName,
      anilistProgress: anilistProgress,
      episodeIndex: episodeIndex,
    );
    if (watched) {
      return 1.0;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl);
    final keyPos = '${prefix}_pos';
    final keyDur = '${prefix}_dur';

    final pos = prefs.getInt(keyPos);
    final dur = prefs.getInt(keyDur);

    if (pos != null && dur != null && dur > 0) {
      return (pos / dur).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  static Future<int?> getAnimeEpisodeProgressPosition({
    required int mediaId,
    required String episodeUrl,
    required String episodeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl);
    final keyPos = '${prefix}_pos';
    final keyDur = '${prefix}_dur';
    final pos = prefs.getInt(keyPos);
    final dur = prefs.getInt(keyDur);
    if (pos != null && dur != null && dur > 0 && pos < dur - 15) {
      return pos;
    }
    return null;
  }
}
