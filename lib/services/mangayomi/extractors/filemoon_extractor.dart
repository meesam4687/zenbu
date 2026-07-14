import 'dart:convert';
import 'package:js_packer/js_packer.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class FilemoonExtractor {
  Future<List<Video>> videosFromUrl(
    String url,
    String prefix,
    String suffix,
  ) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final xp = HtmlXPath.html(res.body);
      final scripts = xp
          .query("//script[contains(text(), 'eval')]/text()")
          .attrs;
      if (scripts.isEmpty) return [];
      final script = scripts.first ?? '';
      final unpacked = JSPacker(script).unpack() ?? '';
      final fileMatch = RegExp(
        r'''\{file:["']([^"']+)["']''',
      ).firstMatch(unpacked);
      if (fileMatch == null) return [];
      final masterUrl = fileMatch.group(1)!;
      List<Track> subtitles = [];
      final subInfoMatch = RegExp(
        r'''sub\.info["']?:\s*["']([^"']+)["']''',
      ).firstMatch(unpacked);
      if (subInfoMatch != null) {
        try {
          final subRes = await client.get(
            Uri.parse(subInfoMatch.group(1)!),
            headers: browserHeaders(url),
          );
          final subList = jsonDecode(subRes.body) as List;
          subtitles = subList
              .map(
                (s) => Track(
                  file: s['file']?.toString(),
                  label: s['label']?.toString(),
                ),
              )
              .toList();
        } catch (_) {}
      }
      final m3u8Res = await client.get(
        Uri.parse(masterUrl),
        headers: browserHeaders(masterUrl),
      );
      final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
      return streams
          .map(
            (s) => Video(
              s['url']!,
              '$prefix - ${s['resolution']}p $suffix',
              masterUrl,
              subtitles: subtitles,
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
