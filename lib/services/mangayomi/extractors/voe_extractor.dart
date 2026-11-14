import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
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

      final currentPlaylistUrl = await _currentPlaylistUrl(
        document,
        Uri.parse(pageUrl),
        client,
      );

      String? masterUrl = currentPlaylistUrl;

      if (masterUrl == null) {
        final scripts = document
            .querySelectorAll('script')
            .map((e) => e.text)
            .toList();
        for (final script in scripts) {
          if (script.contains('const sources') ||
              script.contains('var sources')) {
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
            if (script.contains('wc0') ||
                script.contains('alternativeScript')) {
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
      }

      if (masterUrl == null || masterUrl.isEmpty) return [];

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

  Future<String?> _currentPlaylistUrl(
    Document document,
    Uri pageUri,
    http.Client client,
  ) async {
    try {
      final payloadElement = document.querySelector(
        'script[type="application/json"]',
      );
      final loaderElement = document.querySelector(
        'script[type="application/json"] + script[src]',
      );
      final loaderSource = loaderElement?.attributes['src'];
      if (payloadElement == null || loaderSource == null) {
        return null;
      }

      final payload = json.decode(payloadElement.text);
      if (payload is! List || payload.isEmpty || payload.first is! String) {
        return null;
      }

      final loaderUri = pageUri.resolve(loaderSource);
      final loader = await client.get(
        loaderUri,
        headers: browserHeaders(loaderUri.toString()),
      );
      final lookupTableMatch = RegExp(
        r"\[(?:'\W{2}'\s*(?:,\s*|\])){1,9}",
      ).firstMatch(loader.body);
      if (lookupTableMatch == null) {
        return null;
      }
      final lookupTable = RegExp(r"'([^']+)'")
          .allMatches(lookupTableMatch.group(0)!)
          .map((match) => match.group(1)!)
          .toList();

      var encoded = _rot13(payload.first as String);
      for (final marker in lookupTable) {
        encoded = encoded.replaceAll(marker, '');
      }

      final shifted = utf8.decode(base64.decode(base64.normalize(encoded)));
      final reversedBase64 = String.fromCharCodes(
        shifted.codeUnits.map((codeUnit) => codeUnit - 3),
      ).split('').reversed.join();
      final decoded = json.decode(
        utf8.decode(base64.decode(base64.normalize(reversedBase64))),
      );
      if (decoded is! Map) {
        return null;
      }

      for (final key in const ['source', 'file', 'direct_access_url']) {
        final value = decoded[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {}
    return null;
  }

  String _rot13(String value) {
    final codeUnits = value.codeUnits.map((codeUnit) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        return ((codeUnit - 65 + 13) % 26) + 65;
      }
      if (codeUnit >= 97 && codeUnit <= 122) {
        return ((codeUnit - 97 + 13) % 26) + 97;
      }
      return codeUnit;
    });
    return String.fromCharCodes(codeUnits);
  }
}
