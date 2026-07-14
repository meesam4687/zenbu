import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class VidBomExtractor {
  Future<List<Video>> videosFromUrl(String url) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final xp = HtmlXPath.html(res.body);
      final scripts = xp
          .query("//script[contains(text(), 'sources')]/text()")
          .attrs;
      if (scripts.isEmpty) return [];
      final script = scripts.first ?? '';
      final videos = <Video>[];
      final fileMatches = RegExp(
        r'''file:\s*["']([^"']+)["']''',
      ).allMatches(script);
      final labelMatches = RegExp(
        r'''label:\s*["']([^"']+)["']''',
      ).allMatches(script);
      final files = fileMatches.map((m) => m.group(1)!).toList();
      final labels = labelMatches.map((m) => m.group(1)!).toList();
      for (int i = 0; i < files.length; i++) {
        final label = i < labels.length && labels[i].length <= 15
            ? labels[i]
            : '480p';
        final quality = 'Vidbom - $label';
        videos.add(Video(files[i], quality, files[i]));
      }
      return videos;
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
