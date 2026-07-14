import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class StreamTapeExtractor {
  Future<List<Video>> videosFromUrl(String url, {String? quality}) async {
    final client = buildExtractorClient();
    try {
      final id = RegExp(
        r'streamtape\.(?:com|to)/(?:e|v)/([^/?]+)',
      ).firstMatch(url)?.group(1);
      if (id == null) return [];
      final embedUrl = 'https://streamtape.com/e/$id';
      final res = await client.get(
        Uri.parse(embedUrl),
        headers: browserHeaders(embedUrl),
      );
      final body = res.body;
      final robotMatch = RegExp(
        r'''robotlink.*?innerHTML\s*=\s*(['"])(.*?)\1\s*\+\s*(['"])(.*?)\3''',
        dotAll: true,
      ).firstMatch(body);
      if (robotMatch == null) return [];
      final part1 = robotMatch.group(2)!;
      final part2 = robotMatch.group(4)!;
      final videoUrl = 'https:${part1.trim()}${part2.trim()}';
      return [
        Video(
          videoUrl,
          quality ?? 'StreamTape',
          videoUrl,
          headers: browserHeaders(embedUrl),
        ),
      ];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
