import 'package:zenbu/services/mangayomi/eval/model/filter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_pages.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';

abstract class MProvider {
  MProvider();

  bool get supportsLatest => true;

  String? get baseUrl;

  Map<String, String> get headers => {};

  Future<MPages> getLatestUpdates(int page);

  Future<MPages> getPopular(int page);

  Future<MPages> search(String query, int page, FilterList filterList);

  Future<MManga> getDetail(String url);

  Future<List<dynamic>> getPageList(String url) async => [];

  Future<List<Video>> getVideoList(String url) async => [];

  Future<String> getHtmlContent(String name, String url) async => '';

  Future<String> cleanHtmlContent(String html) async => html;

  List<dynamic> getFilterList() => [];

  List<dynamic> getSourcePreferences() => [];
}
