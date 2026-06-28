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

    if (url.contains('/')) {
      final parts = url.split('/');
      final parsed = double.tryParse(parts.last);
      if (parsed != null) return parsed;
    }

    if (url.contains('|')) {
      final parts = url.split('|');
      final parsed = double.tryParse(parts.last);
      if (parsed != null) return parsed;
    }

    final match = RegExp(
      r'(?:episode|ep|e|chapter|chap|ch)\.?\s*(\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(name);
    if (match != null) return double.tryParse(match.group(1)!);

    final matchAny = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(name);
    if (matchAny != null) return double.tryParse(matchAny.group(1)!);

    return null;
  }

  static String _getMangaKeyPrefix(int mediaId, String url, String name) {
    final num = parseEpisodeNumber(url, name);
    if (num != null) {
      return 'manga_progress_${mediaId}_num_$num';
    }
    return 'manga_progress_${mediaId}_url_$url';
  }

  static String _getAnimeKeyPrefix(int mediaId, String url, String name) {
    final num = parseEpisodeNumber(url, name);
    if (num != null) {
      return 'anime_progress_${mediaId}_num_$num';
    }
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

    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl, chapterName);
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
  }) async {
    final chapterNum = parseEpisodeNumber(chapterUrl, chapterName);
    if (chapterNum != null && chapterNum <= anilistProgress) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl, chapterName);
    final keyRead = '${prefix}_read';
    return prefs.getBool(keyRead) ?? false;
  }

  static Future<Map<String, int>?> getMangaChapterProgress({
    required int mediaId,
    required String chapterUrl,
    required String chapterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _getMangaKeyPrefix(mediaId, chapterUrl, chapterName);
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

    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl, episodeName);
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
  }) async {
    final episodeNum = parseEpisodeNumber(episodeUrl, episodeName);
    if (episodeNum != null && episodeNum <= anilistProgress) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl, episodeName);
    final keyWatched = '${prefix}_watched';
    return prefs.getBool(keyWatched) ?? false;
  }

  static Future<double> getAnimeEpisodeProgressRatio({
    required int mediaId,
    required String episodeUrl,
    required String episodeName,
    required int anilistProgress,
  }) async {
    final watched = await isAnimeEpisodeWatched(
      mediaId: mediaId,
      episodeUrl: episodeUrl,
      episodeName: episodeName,
      anilistProgress: anilistProgress,
    );
    if (watched) {
      return 1.0;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl, episodeName);
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
    final prefix = _getAnimeKeyPrefix(mediaId, episodeUrl, episodeName);
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
