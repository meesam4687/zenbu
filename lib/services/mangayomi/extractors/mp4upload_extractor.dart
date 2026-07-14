import 'package:js_packer/js_packer.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class Mp4uploadExtractor {
  Future<List<Video>> videosFromUrl(
    String url,
    Map<String, String> headers, {
    String prefix = '',
    String suffix = '',
  }) async {
    final client = buildExtractorClient();
    try {
      final reqHeaders = {
        ...browserHeaders(url),
        'Referer': 'https://mp4upload.com/',
        ...headers,
      };
      final res = await client.get(Uri.parse(url), headers: reqHeaders);
      final xp = HtmlXPath.html(res.body);
      final evalScripts = xp
          .query(
            "//script[contains(text(), 'eval') and contains(text(), 'p,a,c,k,e,d')]/text()",
          )
          .attrs;
      String? fileUrl;
      String? resolution;
      if (evalScripts.isNotEmpty) {
        final packed = evalScripts.first ?? '';
        final unpacked = JSPacker(packed).unpack() ?? '';
        final srcMatch = RegExp(
          r'''\.src\(["']([^"']+)["']''',
        ).firstMatch(unpacked);
        if (srcMatch != null) fileUrl = srcMatch.group(1);
        final hMatch = RegExp(r'HEIGHT=(\d+)').firstMatch(unpacked);
        if (hMatch != null) resolution = hMatch.group(1);
      }
      if (fileUrl == null) {
        final playerScripts = xp
            .query("//script[contains(text(), 'player.src')]/text()")
            .attrs;
        if (playerScripts.isNotEmpty) {
          final script = playerScripts.first ?? '';
          final srcMatch = RegExp(
            r'''src:\s*["']([^"']+)["']''',
          ).firstMatch(script);
          if (srcMatch != null) fileUrl = srcMatch.group(1);
        }
      }
      if (fileUrl == null) return [];
      final quality = resolution != null
          ? '$prefix Mp4Upload - ${resolution}p $suffix'
          : '$prefix Mp4Upload $suffix';
      return [Video(fileUrl, quality.trim(), fileUrl, headers: reqHeaders)];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
