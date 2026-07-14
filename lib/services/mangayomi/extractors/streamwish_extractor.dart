import 'package:js_packer/js_packer.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class StreamWishExtractor {
  Future<List<Video>> videosFromUrl(String url, String prefix) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final xp = HtmlXPath.html(res.body);
      final scripts = xp
          .query("//script[contains(text(), 'm3u8')]/text()")
          .attrs;
      if (scripts.isEmpty) return [];
      var script = scripts.first ?? '';
      if (script.contains('function(p,a,c')) {
        script = JSPacker(script).unpack() ?? script;
      }
      final srcMatch = RegExp(
        r'''source[^;]*file:\s*["']([^"']+\.m3u8[^"']*)["']''',
      ).firstMatch(script);
      if (srcMatch == null) return [];
      final masterUrl = srcMatch.group(1)!;
      final m3u8Res = await client.get(
        Uri.parse(masterUrl),
        headers: browserHeaders(masterUrl),
      );
      final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
      return streams
          .map(
            (s) => Video(s['url']!, '$prefix - ${s['resolution']}p', masterUrl),
          )
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
