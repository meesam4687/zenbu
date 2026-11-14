import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, dynamic> userPrefs;
  bool _isInitialized = false;
  late JsCheerio _jsCheerio;

  @override
  int? lastStatusCode;
  @override
  String? lastRequestUrl;

  LNReaderExtensionService(this.source, {Map<String, dynamic>? userPrefs})
    : userPrefs = userPrefs != null ? Map<String, dynamic>.from(userPrefs) : {};

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

    runtime.onMessage('ln_storage_get', (dynamic args) {
      final key = args[0]?.toString();
      if (key == null) return null;
      return _getStoredPreference(key);
    });
    runtime.onMessage('ln_storage_set', (dynamic args) {
      final key = args[0]?.toString();
      if (key == null) return null;
      _setStoredPreference(key, args[1]);
      return null;
    });
    runtime.onMessage('ln_storage_delete', (dynamic args) {
      final key = args[0]?.toString();
      if (key == null) return null;
      _deleteStoredPreference(key);
      return null;
    });

    final pId = source.id != null ? source.id.toString() : 'default';
    runtime.evaluate('''
var require = (package) => {
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
        return {fetchApi: globalThis.fetchApi, fetchText: globalThis.fetchText};
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
        if (!globalThis._lnStorage) globalThis._lnStorage = {};
        const pId = "$pId";
        const getStoreKey = (k) => pId + "_DB_" + k;
        return {
          storage: {
            get: (key, raw) => {
              const fullKey = getStoreKey(key);
              const item = globalThis._lnStorage[fullKey];
              if (item !== undefined) {
                if (item.expires && Date.now() > item.expires) {
                  delete globalThis._lnStorage[fullKey];
                  return undefined;
                }
                return raw ? item : item.value;
              }
              try {
                const fromDart = sendMessage("ln_storage_get", JSON.stringify([key]));
                if (fromDart !== undefined && fromDart !== null) {
                  return raw ? { created: new Date(), value: fromDart } : fromDart;
                }
              } catch (_) {}
              if (typeof extension !== "undefined" && extension && extension.pluginSettings && extension.pluginSettings[key]) {
                const defVal = extension.pluginSettings[key].value;
                if (defVal !== undefined) {
                  return raw ? { created: new Date(), value: defVal } : defVal;
                }
              }
              return undefined;
            },
            set: (key, value, expires) => {
              const fullKey = getStoreKey(key);
              let exp = expires;
              if (exp instanceof Date) exp = exp.getTime();
              globalThis._lnStorage[fullKey] = {
                created: new Date(),
                value: value,
                expires: exp
              };
              try {
                sendMessage("ln_storage_set", JSON.stringify([key, value]));
              } catch (_) {}
            },
            delete: (key) => {
              delete globalThis._lnStorage[getStoreKey(key)];
              try {
                sendMessage("ln_storage_delete", JSON.stringify([key]));
              } catch (_) {}
            },
            clearAll: () => {
              const prefix = pId + "_DB_";
              Object.keys(globalThis._lnStorage).forEach(k => {
                if (k.startsWith(prefix)) delete globalThis._lnStorage[k];
              });
            },
            getAllKeys: () => {
              const prefix = pId + "_DB_";
              return Object.keys(globalThis._lnStorage)
                .filter(k => k.startsWith(prefix))
                .map(k => k.replace(prefix, ''));
            }
          },
          localStorage: {
            get: () => {
              const data = globalThis._lnStorage[pId + "_LocalStorage"];
              return data !== undefined ? data : undefined;
            }
          },
          sessionStorage: {
            get: () => {
              const data = globalThis._lnStorage[pId + "_SessionStorage"];
              return data !== undefined ? data : undefined;
            }
          }
        };
    default:
        return {};
  }
};
globalThis.require = require;
''');
    runtime.evaluate('''
${source.sourceCode ?? ''}
var extension = (typeof exports !== "undefined" && exports.default) ? exports.default : ((typeof module !== "undefined" && module.exports) ? module.exports : null);
globalThis.extension = extension;
async function jsonStringify(fn) {
  return JSON.stringify(await fn());
}
''');
    _isInitialized = true;
  }

  dynamic _getStoredPreference(String key) {
    if (userPrefs.containsKey(key)) {
      return userPrefs[key];
    }
    return null;
  }

  void _setStoredPreference(String key, dynamic val) {
    userPrefs[key] = val;
    if (source.id != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('ext_pref_${source.id}_$key', jsonEncode(val));
      });
    }
  }

  void _deleteStoredPreference(String key) {
    userPrefs.remove(key);
    if (source.id != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('ext_pref_${source.id}_$key');
      });
    }
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
    _init();
    return {};
  }

  @override
  bool get supportsLatest => true;

  @override
  String get sourceBaseUrl => source.baseUrl ?? '';

  @override
  Future<MPages> getPopular(int page) async {
    final List rawList = await _extensionCallAsync(
      'popularNovels($page, {})',
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
      'popularNovels($page, {filters: ${jsonEncode(filters)}})',
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
    chapters = item.chapters ?? [];

    if (chapters.isEmpty || (item.totalPages != null && item.totalPages! > 1)) {
      final paginatedChapters = <ChapterItem>[...chapters];
      int pageNum = paginatedChapters.isEmpty ? 1 : 2;
      final maxPages = item.totalPages ?? 50;
      while (pageNum <= maxPages) {
        try {
          final raw = await _extensionCallAsync<dynamic>(
            'parsePage(${jsonEncode(item.path)}, ${jsonEncode(pageNum.toString())})',
            null,
          );
          if (raw == null || raw is! Map) break;
          final sourcePage = SourcePage.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (sourcePage.chapters.isEmpty) break;
          paginatedChapters.addAll(sourcePage.chapters);
          if (item.totalPages == null &&
              (sourcePage.chapters.length < 5 || pageNum >= 50)) {
            break;
          }
          pageNum++;
        } catch (_) {
          break;
        }
      }
      if (paginatedChapters.isNotEmpty) {
        chapters = paginatedChapters;
      }
    }

    final chaps = chapters
        .map(
          (e) => MChapter(
            name: e.name,
            url: e.path,
            scanlator: e.scanlator,
            dateUpload: e.releaseTime != null
                ? DateTime.tryParse(
                        e.releaseTime!,
                      )?.millisecondsSinceEpoch.toString() ??
                      int.tryParse(e.releaseTime!)?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString()
                : DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        )
        .toList();

    return MManga(
      name: item.name,
      imageUrl: item.cover,
      link: item.path,
      artist: item.artist,
      author: item.author,
      description: item.summary,
      status: switch (item.status?.toLowerCase()) {
        "ongoing" => Status.ongoing,
        "completed" || "publishing finished" => Status.completed,
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
    _init();
    try {
      final res = runtime.evaluate('JSON.stringify(extension.pluginSettings)');
      final decoded = jsonDecode(res.stringResult);
      if (decoded == null) return [];

      final list = <SourcePreference>[];

      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, val) {
          if (val is! Map) return;
          final pref = _mapPluginSettingToSourcePreference(
            key,
            Map<String, dynamic>.from(val),
          );
          if (pref != null) {
            list.add(pref);
          }
        });
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final key = item['key']?.toString();
            if (key != null &&
                (item['switchPreferenceCompat'] != null ||
                    item['checkBoxPreference'] != null ||
                    item['listPreference'] != null ||
                    item['multiSelectListPreference'] != null ||
                    item['editTextPreference'] != null)) {
              list.add(
                SourcePreference.fromJson(Map<String, dynamic>.from(item))
                  ..sourceId = source.id,
              );
            } else if (key != null) {
              final pref = _mapPluginSettingToSourcePreference(
                key,
                Map<String, dynamic>.from(item),
              );
              if (pref != null) list.add(pref);
            }
          }
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  SourcePreference? _mapPluginSettingToSourcePreference(
    String key,
    Map<String, dynamic> setting,
  ) {
    final label = setting['label']?.toString() ?? key;
    final type = setting['type']?.toString();
    final defaultValue = setting['value'];

    final savedValue = userPrefs[key];

    if (type == 'Switch' || (type == null && defaultValue is bool)) {
      final currentVal = (savedValue is bool)
          ? savedValue
          : (defaultValue is bool ? defaultValue : false);
      return SourcePreference(
        key: key,
        sourceId: source.id,
        switchPreferenceCompat: SwitchPreferenceCompat(
          title: label,
          summary: '',
          value: currentVal,
        ),
      );
    }

    if (type == 'Select') {
      final rawOptions = setting['options'];
      final options = rawOptions is List ? rawOptions : [];
      final entries = <String>[];
      final entryValues = <String>[];
      for (final opt in options) {
        if (opt is Map) {
          entries.add(opt['label']?.toString() ?? '');
          entryValues.add(opt['value']?.toString() ?? '');
        }
      }
      final curVal = savedValue?.toString() ?? (defaultValue?.toString() ?? '');
      final idx = entryValues.indexOf(curVal);
      return SourcePreference(
        key: key,
        sourceId: source.id,
        listPreference: ListPreference(
          title: label,
          summary: '',
          entries: entries,
          entryValues: entryValues,
          valueIndex: idx >= 0 && idx < entries.length ? idx : 0,
        ),
      );
    }

    if (type == 'CheckboxGroup') {
      final rawOptions = setting['options'];
      final options = rawOptions is List ? rawOptions : [];
      final entries = <String>[];
      final entryValues = <String>[];
      for (final opt in options) {
        if (opt is Map) {
          entries.add(opt['label']?.toString() ?? '');
          entryValues.add(opt['value']?.toString() ?? '');
        }
      }
      final curVals = (savedValue is List)
          ? savedValue.map((e) => e.toString()).toList()
          : (defaultValue is List
                ? defaultValue.map((e) => e.toString()).toList()
                : <String>[]);
      return SourcePreference(
        key: key,
        sourceId: source.id,
        multiSelectListPreference: MultiSelectListPreference(
          title: label,
          summary: '',
          entries: entries,
          entryValues: entryValues,
          values: curVals,
        ),
      );
    }

    final curVal = savedValue?.toString() ?? (defaultValue?.toString() ?? '');
    return SourcePreference(
      key: key,
      sourceId: source.id,
      editTextPreference: EditTextPreference(
        title: label,
        summary: '',
        value: curVal,
        dialogTitle: label,
      ),
    );
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
