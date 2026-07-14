import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class VoeExtractor {
  Future<List<Video>> videosFromUrl(String url, String? prefix) async {
    final client = buildExtractorClient();
    try {
      var pageUrl = url;
      final res = await client.get(
        Uri.parse(pageUrl),
        headers: browserHeaders(pageUrl),
      );
      var body = res.body;
      final redirMatch = RegExp(
        r'''window\.location\.href\s*=\s*['"]([^'"]+)['"]''',
      ).firstMatch(body);
      if (redirMatch != null) {
        pageUrl = redirMatch.group(1)!;
        final res2 = await client.get(
          Uri.parse(pageUrl),
          headers: browserHeaders(pageUrl),
        );
        body = res2.body;
      }
      final document = html_parser.parse(body);
      final scripts = document
          .querySelectorAll('script')
          .map((e) => e.text)
          .toList();
      String? masterUrl;
      for (final script in scripts) {
        if (script.contains('const sources')) {
          final hlsMatch = RegExp(
            r'''hls:\s*['"]([^'"]+)['"]''',
          ).firstMatch(script);
          if (hlsMatch != null) {
            var hls = hlsMatch.group(1)!;
            if (!hls.startsWith('http')) {
              hls = utf8.decode(base64.decode(hls));
            }
            masterUrl = hls;
            break;
          }
        }
      }
      if (masterUrl == null) {
        for (final script in scripts) {
          if (script.contains('wc0') || script.contains('alternativeScript')) {
            final b64Match = RegExp(
              r'''['"]([A-Za-z0-9+/=]{20,})['"](?:\s*\.split)?(?:\s*,)?\s*(?:;|\))''',
            ).firstMatch(script);
            if (b64Match != null) {
              try {
                var decoded = utf8.decode(base64.decode(b64Match.group(1)!));
                if (script.contains('alternativeScript')) {
                  decoded = String.fromCharCodes(
                    decoded.runes.toList().reversed,
                  );
                }
                final jsonData = jsonDecode(decoded);
                masterUrl = jsonData['file']?.toString();
                break;
              } catch (_) {}
            }
          }
        }
      }
      if (masterUrl == null) return [];
      final m3u8Res = await client.get(
        Uri.parse(masterUrl),
        headers: browserHeaders(masterUrl),
      );
      final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
      return streams
          .map(
            (s) => Video(
              s['url']!,
              '${prefix ?? ''}Voe: ${s['resolution']}p',
              masterUrl!,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
