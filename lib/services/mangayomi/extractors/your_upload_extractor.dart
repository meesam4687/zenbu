import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class YourUploadExtractor {
  Future<List<Video>> videosFromUrl(
    String url,
    Map<String, String> headers, {
    String name = 'YourUpload',
    String prefix = '',
  }) async {
    final client = buildExtractorClient();
    try {
      final reqHeaders = {
        ...browserHeaders(url),
        'Referer': 'https://www.yourupload.com/',
        ...headers,
      };
      final res = await client.get(Uri.parse(url), headers: reqHeaders);
      final xp = HtmlXPath.html(res.body);
      final scripts = xp
          .query("//script[contains(text(), 'jwplayerOptions')]/text()")
          .attrs;
      if (scripts.isEmpty) return [];
      final script = scripts.first ?? '';
      final fileMatch = RegExp(
        r'''file:\s*['"]([^'"]+)['"]''',
      ).firstMatch(script);
      if (fileMatch == null) return [];
      final fileUrl = fileMatch.group(1)!;
      return [Video(fileUrl, '$prefix$name', fileUrl, headers: reqHeaders)];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
