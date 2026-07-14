import 'package:zenbu/services/mangayomi/eval/model/filter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_pages.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/eval/model/source_preference.dart';

class PageUrl {
  String url;
  Map<String, String>? headers;

  PageUrl(this.url, {this.headers});

  factory PageUrl.fromJson(Map<String, dynamic> json) {
    return PageUrl(
      json['url']?.toString() ?? '',
      headers: json['headers'] != null
          ? (json['headers'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'headers': headers};
}

abstract interface class ExtensionService {
  late Source source;

  int? get lastStatusCode;
  String? get lastRequestUrl;

  String get sourceBaseUrl;
  bool get supportsLatest;

  void dispose();

  Map<String, String> getHeaders();

  Future<MPages> getPopular(int page);

  Future<MPages> getLatestUpdates(int page);

  Future<MPages> search(String query, int page, List<dynamic> filters);

  Future<MManga> getDetail(String url);

  Future<List<PageUrl>> getPageList(String url);

  Future<List<Video>> getVideoList(String url);

  Future<String> getHtmlContent(String name, String url);

  Future<String> cleanHtmlContent(String html);

  FilterList getFilterList();

  List<SourcePreference> getSourcePreferences();
}
