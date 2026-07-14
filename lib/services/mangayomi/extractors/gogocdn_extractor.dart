import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/crypto_utils.dart';
import 'extractor_client.dart';

class GogoCdnExtractor {
  Future<List<Video>> videosFromUrl(String serverUrl) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(serverUrl),
        headers: browserHeaders(serverUrl),
      );
      final document = html_parser.parse(res.body);
      final wrapperClass = document.querySelector('.wrapper')?.className ?? '';
      final bodyClass = document.querySelector('body')?.className ?? '';
      final ivMatch = RegExp(r'wrapper-(.+)').firstMatch(wrapperClass);
      final skMatch = RegExp(r'container-(.+)').firstMatch(bodyClass);
      final dkElement = document.querySelector('[class*="videocontent-"]');
      final dkMatch = RegExp(
        r'videocontent-(\d+)',
      ).firstMatch(dkElement?.className ?? '');
      if (ivMatch == null || skMatch == null || dkMatch == null) return [];
      final iv = ivMatch.group(1)!;
      final secretKey = skMatch.group(1)!;
      final decryptionKey = dkMatch.group(1)!;
      final dataValue =
          document
              .querySelector('div.videocontent')
              ?.attributes['data-value'] ??
          '';
      final videoId = Uri.parse(serverUrl).queryParameters['id'] ?? '';
      final decrypted = CryptoAES.cryptoHandler(
        dataValue,
        iv,
        secretKey,
        false,
      );
      final encrypted = CryptoAES.cryptoHandler(
        '$decrypted&id=$videoId',
        iv,
        secretKey,
        true,
      );
      final host =
          '${Uri.parse(serverUrl).scheme}://${Uri.parse(serverUrl).host}';
      final encAjaxRes = await client.get(
        Uri.parse('$host/encrypt-ajax.php?id=$encrypted'),
        headers: {
          ...browserHeaders(serverUrl),
          'X-Requested-With': 'XMLHttpRequest',
        },
      );
      final decData = CryptoAES.cryptoHandler(
        jsonDecode(encAjaxRes.body)['data'] as String,
        iv,
        decryptionKey,
        false,
      );
      final sources =
          (jsonDecode(decData)['source'] ?? jsonDecode(decData)['source_bk'])
              as List?;
      if (sources == null) return [];
      final isToken = serverUrl.contains('token');
      final prefix = isToken ? 'Vidstreaming - ' : 'Gogostream - ';
      final videos = <Video>[];
      for (final s in sources) {
        final file = s['file']?.toString() ?? '';
        final label = s['label']?.toString() ?? 'Auto';
        if (file.contains('.m3u8')) {
          final m3u8Res = await client.get(
            Uri.parse(file),
            headers: browserHeaders(file),
          );
          final streams = parseM3u8Streams(m3u8Res.body, file);
          for (final st in streams) {
            videos.add(Video(st['url']!, '$prefix${st['resolution']}p', file));
          }
          if (streams.isEmpty) videos.add(Video(file, '${prefix}Auto', file));
        } else {
          videos.add(Video(file, '$prefix$label', file));
        }
      }
      return videos;
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
