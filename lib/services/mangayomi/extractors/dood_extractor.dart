import 'dart:math';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class DoodExtractor {
  Future<List<Video>> videosFromUrl(String url, {String? quality}) async {
    final client = buildExtractorClient();
    try {
      final res = await client.get(
        Uri.parse(url),
        headers: browserHeaders(url),
      );
      final body = res.body;
      final redirectMatch = RegExp(
        r'''window\.location\.href\s*=\s*['"]([^'"]+)['"]''',
      ).firstMatch(body);
      String doodUrl = url;
      if (redirectMatch != null) {
        final redir = redirectMatch.group(1)!;
        doodUrl = redir.startsWith('http')
            ? redir
            : Uri.parse(url).resolve(redir).toString();
        final res2 = await client.get(
          Uri.parse(doodUrl),
          headers: browserHeaders(doodUrl),
        );
        return _parse(client, doodUrl, res2.body, quality);
      }
      return _parse(client, doodUrl, body, quality);
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  Future<List<Video>> _parse(
    dynamic client,
    String doodUrl,
    String body,
    String? quality,
  ) async {
    final md5Match = RegExp(r'''pass_md5/([^'"]+)''').firstMatch(body);
    if (md5Match == null) return [];
    final md5Path = md5Match.group(1)!;
    final tokenMatch = RegExp(r'''token=([^&'"]+)''').firstMatch(body);
    if (tokenMatch == null) return [];
    final token = tokenMatch.group(1)!;
    final host = Uri.parse(doodUrl).host;
    final md5Url = 'https://$host/pass_md5/$md5Path';
    final md5Res = await client.get(
      Uri.parse(md5Url),
      headers: browserHeaders(doodUrl),
    );
    final videoBase = md5Res.body;
    final random = List.generate(
      10,
      (_) =>
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'[Random()
              .nextInt(62)],
    ).join();
    final expiry = DateTime.now().millisecondsSinceEpoch;
    final videoUrl = '$videoBase$random?token=$token&expiry=$expiry';
    return [
      Video(
        videoUrl,
        quality ?? 'Doodstream',
        videoUrl,
        headers: {'User-Agent': 'Mangayomi', 'Referer': 'https://$host/'},
      ),
    ];
  }
}
