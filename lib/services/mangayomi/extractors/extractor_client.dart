import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client buildExtractorClient() {
  final httpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  return IOClient(httpClient);
}

Map<String, String> browserHeaders(String url, {Map<String, String>? extra}) {
  final uri = Uri.tryParse(url);
  final origin = uri != null ? '${uri.scheme}://${uri.host}' : '';
  final headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    if (origin.isNotEmpty) 'Referer': '$origin/',
  };
  if (extra != null) headers.addAll(extra);
  return headers;
}

List<Map<String, String>> parseM3u8Streams(String content, String masterUrl) {
  final results = <Map<String, String>>[];
  final lines = content.split('\n');
  for (int i = 0; i < lines.length - 1; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('#EXT-X-STREAM-INF')) continue;
    final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(line);
    final resolution = resMatch?.group(1)?.split('x').last ?? '';
    final segLine = lines[i + 1].trim();
    if (segLine.isEmpty || segLine.startsWith('#')) continue;
    final segUrl = segLine.startsWith('http')
        ? segLine
        : Uri.parse(masterUrl).resolve(segLine).toString();
    results.add({'resolution': resolution, 'url': segUrl});
  }
  return results;
}
