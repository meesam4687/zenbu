import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/mangayomi/eval/model/filter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_chapter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_pages.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/eval/model/source_preference.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/http.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/js_cheerio.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/js_htmlparser.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/js_libs.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/js_polyfills.dart';
import 'package:zenbu/services/mangayomi/eval/lnreader/m_plugin.dart';

class LNReaderExtensionService implements ExtensionService {
  late JavascriptRuntime runtime;
  @override
  late Source source;
  bool _isInitialized = false;
  late JsCheerio _jsCheerio;

  @override
  int? lastStatusCode;
  @override
  String? lastRequestUrl;

  LNReaderExtensionService(this.source);

  void _init() {
    if (_isInitialized) return;
    runtime = getJavascriptRuntime();
    runtime.evaluate('''
module={},exports=Function("return this")(),Object.defineProperties(module,{namespace:{set:function(a){exports=a}},exports:{set:function(a){for(var b in a)a.hasOwnProperty(b)&&(exports[b]=a[b])},get:function(){return exports}}});
''');
    JsPolyfills(runtime).init();
    JsHttpClient(runtime).init();
    JsLibs(runtime).init();
    JsHtmlParser(runtime).init();
    _jsCheerio = JsCheerio(runtime)..init();
    runtime.evaluate('''
const require = (package) => {
  switch (package) {
    case "htmlparser2":
        return {Parser: Parser};
    case "cheerio":
        return {load: load};
    case "dayjs":
        return module.exports.dayjs;
    case "urlencode":
        return {encode: urlencode, decode: urldecode};
    case "@libs/fetch":
        return {fetchApi: fetchApi};
    case "@libs/novelStatus":
        return {NovelStatus: NovelStatus};
    case "@libs/isAbsoluteUrl":
        return {isUrlAbsolute: isUrlAbsolute};
    case "@libs/filterInputs":
        return {
          FilterTypes: FilterTypes,
          isPickerValue: isPickerValue,
          isCheckboxValue: isCheckboxValue,
          isSwitchValue: isSwitchValue,
          isTextValue: isTextValue,
          isXCheckboxValue: isXCheckboxValue
        };
    case "@libs/defaultCover":
        return {defaultCover: 'https://raw.githubusercontent.com/LNReader/lnreader-plugins/refs/heads/master/public/static/coverNotAvailable.webp'};
    case "@libs/storage":
        return {storage: {get: () => null}};
    default:
        return {};
  }
};
''');
    runtime.evaluate('''
${source.sourceCode ?? ''}
const extension = exports.default;
''');
    _isInitialized = true;
  }

  @override
  void dispose() {
    if (!_isInitialized) return;
    _jsCheerio.dispose();
    runtime.dispose();
    _isInitialized = false;
  }

  @override
  Map<String, String> getHeaders() {
    return {};
  }

  @override
  bool get supportsLatest => true;

  @override
  String get sourceBaseUrl => source.baseUrl ?? '';

  @override
  Future<MPages> getPopular(int page) async {
    final List rawList = await _extensionCallAsync(
      'popularNovels($page, {showLatestNovels: false, filters: extension.filters})',
      [],
    );
    final items = rawList
        .map((e) => NovelItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .map(
          (e) => MManga(
            name: e.name,
            imageUrl: e.cover,
            link: e.path,
            chapters: [],
          ),
        )
        .toList();
    return MPages(list: items, hasNextPage: true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final List rawList = await _extensionCallAsync(
      'popularNovels($page, {showLatestNovels: true, filters: extension.filters})',
      [],
    );
    final items = rawList
        .map((e) => NovelItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .map(
          (e) => MManga(
            name: e.name,
            imageUrl: e.cover,
            link: e.path,
            chapters: [],
          ),
        )
        .toList();
    return MPages(list: items, hasNextPage: true);
  }

  @override
  Future<MPages> search(String query, int page, List<dynamic> filters) async {
    final List rawList = await _extensionCallAsync(
      'searchNovels(${jsonEncode(query)}, $page)',
      [],
    );
    final items = rawList
        .map((e) => NovelItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .map(
          (e) => MManga(
            name: e.name,
            imageUrl: e.cover,
            link: e.path,
            chapters: [],
          ),
        )
        .toList();
    return MPages(list: items, hasNextPage: true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    List<ChapterItem>? chapters = [];
    final rawDetail = await _extensionCallAsync(
      'parseNovel(${jsonEncode(url)})',
      {},
    );
    final item = SourceNovel.fromJson(Map<String, dynamic>.from(rawDetail));
    chapters = item.chapters;

    if (chapters?.isEmpty ?? true) {
      final dynamic rawPage = await _extensionCallAsync(
        'parsePage(${jsonEncode(item.path)}, ${jsonEncode("1")})',
        null,
      );
      if (rawPage != null && rawPage is Map) {
        final sourcePage = SourcePage.fromJson(
          Map<String, dynamic>.from(rawPage),
        );
        if (sourcePage.chapters.isNotEmpty) {
          chapters = sourcePage.chapters;
        }
      }
    }

    final chaps =
        chapters
            ?.map(
              (e) => MChapter(
                name: e.name,
                url: e.path,
                dateUpload: e.releaseTime != null
                    ? DateTime.tryParse(
                            e.releaseTime!,
                          )?.millisecondsSinceEpoch.toString() ??
                          int.tryParse(e.releaseTime!)?.toString() ??
                          DateTime.now().millisecondsSinceEpoch.toString()
                    : DateTime.now().millisecondsSinceEpoch.toString(),
              ),
            )
            .toList() ??
        [];

    return MManga(
      name: item.name,
      imageUrl: item.cover,
      link: item.path,
      artist: item.artist,
      author: item.author,
      description: item.summary,
      status: switch (item.status?.toLowerCase()) {
        "ongoing" => Status.ongoing,
        "completed" => Status.completed,
        "on hiatus" => Status.onHiatus,
        "cancelled" => Status.canceled,
        _ => Status.unknown,
      },
      genre: item.genres?.split(","),
      chapters: chaps.reversed.toList(),
    );
  }

  @override
  Future<List<PageUrl>> getPageList(String url) async {
    return [];
  }

  @override
  Future<List<Video>> getVideoList(String url) async {
    return [];
  }

  @override
  Future<String> getHtmlContent(String name, String url) async {
    _init();
    final res = await runtime.handlePromise(
      await runtime.evaluateAsync(
        'jsonStringify(() => extension.parseChapter(${jsonEncode(url)}))',
      ),
    );
    return res.stringResult;
  }

  @override
  Future<String> cleanHtmlContent(String html) async {
    return html;
  }

  @override
  FilterList getFilterList() {
    List<dynamic> list;
    try {
      list = fromJsonFilterValuesToList(_extensionCall('filters', []));
    } catch (_) {
      list = [];
    }
    return FilterList(list);
  }

  @override
  List<SourcePreference> getSourcePreferences() {
    final List rawList = _extensionCall('pluginSettings', []);
    return rawList
        .map(
          (e) =>
              SourcePreference.fromJson(Map<String, dynamic>.from(e as Map))
                ..sourceId = source.id,
        )
        .toList();
  }

  T _extensionCall<T>(String call, T def) {
    _init();
    try {
      final res = runtime.evaluate('JSON.stringify(extension.$call)');
      return jsonDecode(res.stringResult) as T;
    } catch (_) {
      return def;
    }
  }

  Future<T> _extensionCallAsync<T>(String call, T def) async {
    _init();
    try {
      final promised = await runtime.handlePromise(
        await runtime.evaluateAsync('jsonStringify(() => extension.$call)'),
      );
      return jsonDecode(promised.stringResult) as T;
    } catch (e) {
      if (def != null) {
        return def;
      }
      rethrow;
    }
  }
}
