import 'package:html/parser.dart' as html_parser;
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class MytvExtractor {
  Future<List<Video>> videosFromUrl(String url) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final document = html_parser.parse(res.body);
      final scripts = document.querySelectorAll('script');
      for (final script in scripts) {
        final text = script.text;
        if (!text.contains('CreatePlayer("v")')) continue;
        final vMatch = RegExp(r'''[?&]v=([^&"' ]+)''').firstMatch(text);
        if (vMatch == null) continue;
        final videoUrl = Uri.decodeFull(vMatch.group(1)!);
        return [Video(videoUrl, 'Mytv', videoUrl)];
      }
      return [];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
