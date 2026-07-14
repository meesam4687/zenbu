import 'dart:convert';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'extractor_client.dart';

class StreamlareExtractor {
  Future<List<Video>> videosFromUrl(
    String url, {
    String prefix = '',
    String suffix = '',
  }) async {
    final client = buildExtractorClient();
    try {
      final id = url.split('/').last;
      final apiRes = await client.post(
        Uri.parse('https://slwatch.co/api/video/stream/get'),
        headers: {...browserHeaders(url), 'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final data = jsonDecode(apiRes.body);
      final result = data['result'];
      if (result == null) return [];
      final videos = <Video>[];
      if (result['type'] == 'hls') {
        final masterUrl = result['url']?.toString() ?? '';
        final m3u8Res = await client.get(
          Uri.parse(masterUrl),
          headers: browserHeaders(masterUrl),
        );
        final streams = parseM3u8Streams(m3u8Res.body, masterUrl);
        for (final s in streams) {
          videos.add(
            Video(
              s['url']!,
              '${prefix}Streamlare:${s['resolution']}$suffix',
              masterUrl,
            ),
          );
        }
      } else {
        final streamList = result['streams'] as List? ?? [];
        for (final s in streamList) {
          final label = s['label']?.toString() ?? '';
          final file = s['file']?.toString() ?? '';
          if (file.isNotEmpty) {
            final streamRes = await client.post(
              Uri.parse(file),
              headers: {
                ...browserHeaders(url),
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'id': id}),
            );
            final streamData = jsonDecode(streamRes.body);
            final streamUrl = streamData['result']?.toString() ?? '';
            if (streamUrl.isNotEmpty) {
              videos.add(
                Video(
                  streamUrl,
                  '${prefix}Streamlare:$label$suffix',
                  streamUrl,
                ),
              );
            }
          }
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
