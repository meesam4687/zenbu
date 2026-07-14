import 'package:html/parser.dart' as html_parser;
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class OkruExtractor {
  Future<List<Video>> videosFromUrl(String url) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final document = html_parser.parse(res.body);
      final div = document.querySelector('div[data-options]');
      if (div == null) return [];
      final dataOpts = div.attributes['data-options'] ?? '';
      final unescaped = dataOpts.replaceAll(r'\u0026', '&');
      final hlsMatch = RegExp(
        r'''ondemandHls["']?:["']([^"'&]+)''',
      ).firstMatch(unescaped);
      if (hlsMatch == null) return [];
      final masterUrl = hlsMatch.group(1)!;
      final m3u8Res = await client.get(
        Uri.parse(masterUrl),
        headers: browserHeaders(masterUrl),
      );
      final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
      if (streams.isEmpty) return [Video(masterUrl, 'Okru', masterUrl)];
      return streams
          .map((s) => Video(s['url']!, 'Okru: ${s['resolution']}p', masterUrl))
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
