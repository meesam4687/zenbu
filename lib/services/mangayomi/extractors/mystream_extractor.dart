import 'dart:async';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/utils/extensions/string_extensions.dart';
import 'extractor_client.dart';

class MyStreamExtractor {
  Future<List<Video>> videosFromUrl(
    String url,
    Map<String, String> headers,
  ) async {
    final host = url.substringBefore("/watch");
    final client = buildExtractorClient();

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {...browserHeaders(url), ...headers},
      );

      final document = response.body;
      final streamCode = document
          .substringAfter('${url.substringAfter("?v=")}", "')
          .substringBefore('",null,null');
      final streamUrl = "$host/m3u8/$streamCode/master.txt?s=1&cache=1";

      final cookie = response.headers.entries
          .firstWhere(
            (entry) =>
                entry.key.toLowerCase() == "set-cookie" &&
                entry.value.startsWith("PHPSESSID", 0),
            orElse: () => const MapEntry("set-cookie", ""),
          )
          .value
          .split(";")
          .first;

      final newHeaders = {
        ...browserHeaders(streamUrl),
        ...headers,
        if (cookie.isNotEmpty) "cookie": cookie,
        "accept": "*/*",
      };

      final masterPlaylistResponse = await client.get(
        Uri.parse(streamUrl),
        headers: newHeaders,
      );
      final masterPlaylist = masterPlaylistResponse.body;

      const separator = "#EXT-X-STREAM-INF";
      if (!masterPlaylist.contains(separator)) {
        return [];
      }
      return masterPlaylist.substringAfter(separator).split(separator).map((
        it,
      ) {
        final resolution =
            "${it.substringAfter("RESOLUTION=").substringBefore("\n").substringAfter("x").substringBefore(",")}p";
        final quality = "MyStream - $resolution";
        final videoUrl = it.substringAfter("\n").substringBefore("\n").trim();
        return Video(videoUrl, quality, videoUrl, headers: newHeaders);
      }).toList();
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
