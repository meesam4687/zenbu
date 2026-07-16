import 'package:html/parser.dart' as html_parser;
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class SendvidExtractor {
  final Map<String, String> extraHeaders;
  SendvidExtractor(this.extraHeaders);

  Future<List<Video>> videosFromUrl(String url, {String prefix = ''}) async {
    final client = buildExtractorClient();
    try {
      final headers = browserHeaders(url);
      headers.addAll(extraHeaders);
      final res = await client.get(Uri.parse(url), headers: headers);
      final document = html_parser.parse(res.body);
      final masterUrl = document
          .querySelector('source#video_source')
          ?.attributes['src'];
      if (masterUrl == null) return [];
      final host = Uri.parse(url).host;
      final m3u8Headers = {
        ...headers,
        'Accept': '*/*',
        'Host': host,
        'Origin': '${Uri.parse(url).scheme}://$host',
      };
      final m3u8Res = await client.get(
        Uri.parse(masterUrl),
        headers: m3u8Headers,
      );
      final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
      if (streams.isEmpty) {
        return [Video(masterUrl, '${prefix}Sendvid', masterUrl)];
      }
      return streams
          .map(
            (s) => Video(
              s['url']!,
              '${prefix}Sendvid:${s['resolution']}p',
              masterUrl,
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
