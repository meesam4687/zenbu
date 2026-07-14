import 'dart:collection';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/dom_selector.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/extractors.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/http.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/preferences.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/utils.dart';
import 'package:zenbu/services/mangayomi/eval/model/filter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_pages.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/eval/model/source_preference.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';

class JsExtensionService implements ExtensionService {
  late JavascriptRuntime runtime;
  @override
  late Source source;
  final Map<String, dynamic> userPrefs;
  bool _isInitialized = false;
  late JsDomSelector _jsDomSelector;
  @override
  int? lastStatusCode;
  @override
  String? lastRequestUrl;

  JsExtensionService(this.source, {this.userPrefs = const {}});

  void _init() {
    if (_isInitialized) return;
    runtime = getJavascriptRuntime();
    JsHttpClient(runtime, service: this).init();
    _jsDomSelector = JsDomSelector(runtime)..init();
    JsUtils(runtime).init();
    JsVideosExtractors(runtime).init();
    JsPreferences(runtime, source).init();

    final sourceJson = jsonEncode(source.toMSource().toJson());
    final prefsJson = jsonEncode(userPrefs);

    runtime.evaluate('var _userPrefs = $prefsJson;');
    runtime.evaluate('''
      class MProvider {
        get source() {
          return $sourceJson;
        }
        get supportsLatest() {
          return false;
        }
        getHeaders(url) {
          return {};
        }
        async getPopular(page) {
          throw new Error("getPopular not implemented");
        }
        async getLatestUpdates(page) {
          throw new Error("getLatestUpdates not implemented");
        }
        async search(query, page, filters) {
          throw new Error("search not implemented");
        }
        async getDetail(url) {
          throw new Error("getDetail not implemented");
        }
        async getPageList() {
          throw new Error("getPageList not implemented");
        }
        async getVideoList(url) {
          throw new Error("getVideoList not implemented");
        }
        async getHtmlContent(name, url) {
          throw new Error("getHtmlContent not implemented");
        }
        async cleanHtmlContent(html) {
          return html;
        }
        getFilterList() {
          return [];
        }
        getSourcePreferences() {
          return [];
        }
      }
      async function jsonStringify(fn) {
        return JSON.stringify(await fn());
      }
    ''');

    String sourceCode = source.sourceCode ?? '';
    // Zenbu Custom Patch: Safe replacement for .map(rel => rel.attributes.name)
    if (sourceCode.contains('.map(rel => rel.attributes.name)')) {
      sourceCode = sourceCode.replaceAll(
        '.map(rel => rel.attributes.name)',
        '.map(rel => (rel.attributes && rel.attributes.name) ? rel.attributes.name : "")',
      );
    }

    runtime.evaluate(sourceCode);

    // Zenbu Custom JS prototype overrides
    runtime.evaluate(r'''
      if (typeof DefaultExtension !== 'undefined') {
        DefaultExtension.prototype.originalB64dec = DefaultExtension.prototype.b64dec;
        DefaultExtension.prototype.b64dec = function(str) {
          if (str && str.length > 100) {
            return JSON.parse(sendMessage('native_b64dec', JSON.stringify([str])));
          }
          return this.originalB64dec(str);
        };
        DefaultExtension.prototype.inflate = function(data) {
          return JSON.parse(sendMessage('native_inflate', JSON.stringify([data])));
        };
        if (typeof DefaultExtension.prototype.getDetail === 'function') {
          DefaultExtension.prototype.originalGetDetail = DefaultExtension.prototype.getDetail;
          DefaultExtension.prototype.getDetail = function(url) {
            if (url && typeof url === 'string' && url.includes('/')) {
              const lastSegment = url.split('/').filter(Boolean).pop();
              if (/^\d+$/.test(lastSegment)) {
                try {
                  return this.originalGetDetail(url);
                } catch (e) {
                  return this.originalGetDetail(lastSegment);
                }
              }
            }
            return this.originalGetDetail(url);
          };
        }
        if (typeof DefaultExtension.prototype.getFilterList === 'function') {
          DefaultExtension.prototype.originalGetFilterList = DefaultExtension.prototype.getFilterList;
          DefaultExtension.prototype.getFilterList = function() {
            try {
              const list = this.originalGetFilterList() || [];
              for (let i = 0; i < list.length; i++) {
                const filter = list[i];
                if (filter && filter.type_name === 'SelectFilter' && filter.state === undefined) {
                  filter.state = 0;
                }
              }
              return list;
            } catch (e) {
              console.log("Error in getFilterList: " + e);
              return [];
            }
          };
        }
        if (typeof DefaultExtension.prototype.search === 'function') {
          DefaultExtension.prototype.originalSearch = DefaultExtension.prototype.search;
          DefaultExtension.prototype.search = function(query, page, filters) {
            try {
              if (!filters || filters.length === 0) {
                filters = this.getFilterList() || [];
              }
              for (let i = 0; i < filters.length; i++) {
                const filter = filters[i];
                if (filter) {
                  if (filter.type_name === 'SelectFilter' && filter.state === undefined) {
                    filter.state = 0;
                  }
                  if (filter.state === undefined) {
                    if (filter.values !== undefined) {
                      filter.state = 0;
                    } else {
                      filter.state = [];
                    }
                  }
                }
              }
              return this.originalSearch(query, page, filters);
            } catch (e) {
              console.log("Error in search: " + e);
              throw e;
            }
          };
        }
      }
      var extension = new DefaultExtension();
    ''');

    _isInitialized = true;
  }

  @override
  void dispose() {
    if (!_isInitialized) return;
    _jsDomSelector.dispose();
    runtime.dispose();
    _isInitialized = false;
  }

  @override
  Map<String, String> getHeaders() {
    final Map decoded = _extensionCall<Map>(
      'getHeaders(${jsonEncode(source.baseUrl ?? '')})',
      {},
    );
    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  @override
  bool get supportsLatest {
    return _extensionCall<bool>('supportsLatest', false);
  }

  @override
  String get sourceBaseUrl {
    return source.baseUrl ?? '';
  }

  @override
  Future<MPages> getPopular(int page) async {
    final Map<String, dynamic> res = await _extensionCallAsync(
      'getPopular($page)',
    );
    return MPages.fromJson(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final Map<String, dynamic> res = await _extensionCallAsync(
      'getLatestUpdates($page)',
    );
    return MPages.fromJson(res);
  }

  @override
  Future<MPages> search(String query, int page, List<dynamic> filters) async {
    if (filters.isEmpty) {
      try {
        filters = getFilterList().filters;
      } catch (_) {}
    }
    final Map<String, dynamic> res = await _extensionCallAsync(
      'search(${jsonEncode(query)}, $page, ${jsonEncode(filterValuesListToJson(filters))})',
    );
    return MPages.fromJson(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final Map<String, dynamic> res = await _extensionCallAsync(
      'getDetail(${jsonEncode(url)})',
    );
    return MManga.fromJson(res);
  }

  @override
  Future<List<PageUrl>> getPageList(String url) async {
    final pages = LinkedHashSet<PageUrl>(
      equals: (a, b) => a.url == b.url,
      hashCode: (p) => p.url.hashCode,
    );

    final List rawList = await _extensionCallAsync(
      'getPageList(${jsonEncode(url)})',
    );
    for (final e in rawList) {
      if (e != null) {
        final page = e is String
            ? PageUrl(e.trim())
            : PageUrl.fromJson(Map<String, dynamic>.from(e as Map));
        pages.add(page);
      }
    }
    return pages.toList();
  }

  @override
  Future<List<Video>> getVideoList(String url) async {
    final videos = LinkedHashSet<Video>(
      equals: (a, b) => a.url == b.url && a.originalUrl == b.originalUrl,
      hashCode: (v) => Object.hash(v.url, v.originalUrl),
    );

    final List rawList = await _extensionCallAsync(
      'getVideoList(${jsonEncode(url)})',
    );
    for (final element in rawList) {
      if (element != null && element is Map && element['url'] != null) {
        final map = Map<String, dynamic>.from(element);
        videos.add(Video.fromJson(map));
      }
    }
    return videos.toList();
  }

  @override
  Future<String> getHtmlContent(String name, String url) async {
    _init();
    final res = await runtime.handlePromise(
      await runtime.evaluateAsync(
        'jsonStringify(() => extension.getHtmlContent(${jsonEncode(name)}, ${jsonEncode(url)}))',
      ),
    );
    return res.stringResult;
  }

  @override
  Future<String> cleanHtmlContent(String html) async {
    _init();
    final res = await runtime.handlePromise(
      await runtime.evaluateAsync(
        'jsonStringify(() => extension.cleanHtmlContent(${jsonEncode(html)}))',
      ),
    );
    return res.stringResult;
  }

  Future<String?> fetchUrl(String url, Map<String, String> headers) async {
    _init();
    try {
      final escapedUrl = url.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      final headersJson = json.encode(headers);
      final res = runtime.evaluate(
        'jsonStringify(extension.client.get("$escapedUrl", $headersJson))',
      );
      final resolved = await runtime.handlePromise(res);
      final data = json.decode(resolved.stringResult);
      if (data is Map && data['statusCode'] == 200) {
        return data['body'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  FilterList getFilterList() {
    List<dynamic> list;
    try {
      final List rawList = _extensionCall('getFilterList()', []);
      list = fromJsonFilterValuesToList(rawList);
    } catch (_) {
      list = [];
    }
    return FilterList(list);
  }

  @override
  List<SourcePreference> getSourcePreferences() {
    final List rawList = _extensionCall('getSourcePreferences()', []);
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

  Future<T> _extensionCallAsync<T>(String call) async {
    _init();
    try {
      final promised = await runtime.handlePromise(
        await runtime.evaluateAsync('jsonStringify(() => extension.$call)'),
      );
      return jsonDecode(promised.stringResult) as T;
    } catch (e) {
      rethrow;
    }
  }
}
