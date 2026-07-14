import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class SibnetExtractor {
  Future<List<Video>> videosFromUrl(String url, {String prefix = ''}) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      if (res.statusCode != 200) return [];
      final srcMatch = RegExp(
        r'''player\.src\([^)]*src:\s*["']([^"']+)["']''',
      ).firstMatch(res.body);
      if (srcMatch == null) return [];
      var slug = srcMatch.group(1)!;
      if (!slug.startsWith('http')) {
        slug = '${Uri.parse(url).scheme}://${Uri.parse(url).host}$slug';
      }
      return [
        Video(slug, '$prefix - Sibnet', slug, headers: {'Referer': url}),
      ];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
