import 'package:d4rt/d4rt.dart';
import 'package:flutter/foundation.dart';
import 'package:zenbu/services/mangayomi/eval/dart/bridge/registrer.dart';
import 'package:zenbu/services/mangayomi/eval/model/filter.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_pages.dart';
import 'package:zenbu/services/mangayomi/eval/model/source_preference.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/eval/dart/bridge/m_provider.dart';

class DartExtensionService implements ExtensionService {
  @override
  late Source source;
  D4rt? _interpreter;

  @override
  int? get lastStatusCode => null;

  @override
  String? get lastRequestUrl => null;

  DartExtensionService(this.source) {
    _interpreter = D4rt();
    RegistrerBridge.registerBridge(_interpreter!);

    _interpreter!.execute(
      source: source.sourceCode!.replaceAll('Client(source)', 'Client()'),
      positionalArgs: [source.toMSource()],
    );

    try {
      final prefs = getSourcePreferences();
      final map = <String, dynamic>{};
      for (final p in prefs) {
        if (p.listPreference != null) {
          final lp = p.listPreference!;
          final idx = lp.valueIndex ?? 0;
          if (lp.entryValues != null &&
              idx >= 0 &&
              idx < lp.entryValues!.length) {
            map[p.key!] = lp.entryValues![idx];
          }
        } else if (p.checkBoxPreference != null) {
          map[p.key!] = p.checkBoxPreference!.value;
        } else if (p.switchPreferenceCompat != null) {
          map[p.key!] = p.switchPreferenceCompat!.value;
        } else if (p.editTextPreference != null) {
          map[p.key!] = p.editTextPreference!.value;
        } else if (p.multiSelectListPreference != null) {
          map[p.key!] = p.multiSelectListPreference!.values;
        }
      }
      ExtPreferences.init(source.id ?? 0, map);
    } catch (_) {}
  }

  @override
  void dispose() {
    _interpreter = null;
  }

  @override
  Map<String, String> getHeaders() {
    try {
      return (_interpreter!.invoke('headers', []) as Map)
          .cast<String, String>();
    } catch (_) {
      try {
        return (_interpreter!.invoke('getHeader', [source.baseUrl!]) as Map)
            .cast<String, String>();
      } catch (_) {
        return {};
      }
    }
  }

  @override
  String get sourceBaseUrl {
    try {
      final baseUrl = _interpreter!.invoke('baseUrl', []) as String?;
      return (baseUrl == null || baseUrl.isEmpty) ? source.baseUrl! : baseUrl;
    } catch (_) {
      return source.baseUrl!;
    }
  }

  @override
  bool get supportsLatest {
    try {
      return _interpreter!.invoke('supportsLatest', []) as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<MPages> getPopular(int page) async =>
      await _interpreter!.invoke('getPopular', [page]) as MPages;

  @override
  Future<MPages> getLatestUpdates(int page) async =>
      await _interpreter!.invoke('getLatestUpdates', [page]) as MPages;

  @override
  Future<MPages> search(String query, int page, List<dynamic> filters) async {
    if (filters.isEmpty) {
      try {
        filters = getFilterList().filters;
      } catch (_) {}
    }
    return await _interpreter!.invoke('search', [
          query,
          page,
          FilterList(filters),
        ])
        as MPages;
  }

  @override
  Future<MManga> getDetail(String url) async =>
      await _interpreter!.invoke('getDetail', [url]) as MManga;

  @override
  Future<List<PageUrl>> getPageList(String url) async {
    final result = await _interpreter!.invoke('getPageList', [url]) as List;
    return result.map((e) {
      if (e is String) return PageUrl(e.trim());
      return PageUrl.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
  }

  @override
  Future<List<Video>> getVideoList(String url) async =>
      (await _interpreter!.invoke('getVideoList', [url]) as List).cast<Video>();

  @override
  Future<String> getHtmlContent(String url, String? referer) async =>
      await _interpreter!.invoke('getHtmlContent', [url, referer]) as String;

  @override
  Future<String> cleanHtmlContent(String html) async =>
      await _interpreter!.invoke('cleanHtmlContent', [html]) as String;

  @override
  FilterList getFilterList() {
    List<dynamic> list = [];
    try {
      list = _interpreter!.invoke('getFilterList', []) as List;
    } catch (e, st) {
      if (kDebugMode) {
        print('[DartExtensionService] getFilterList failed: $e\n$st');
      }
    }

    return FilterList(_toValueList(list));
  }

  List _toValueList(List filters) {
    return (filters).map((e) {
      if (e is BridgedInstance) {
        e = e.nativeObject;
      }
      if (e is SelectFilter) {
        return SelectFilter(
          e.type,
          e.name,
          e.state,
          _toValueList(e.values),
          e.typeName,
        );
      } else if (e is SortFilter) {
        return SortFilter(
          e.type,
          e.name,
          e.state,
          _toValueList(e.values),
          e.typeName,
        );
      } else if (e is GroupFilter) {
        return GroupFilter(e.type, e.name, _toValueList(e.state), e.typeName);
      }
      return e;
    }).toList();
  }

  @override
  List<SourcePreference> getSourcePreferences() {
    try {
      final result = _interpreter!.invoke('getSourcePreferences', []);
      return (result as List).cast();
    } catch (_) {
      return const [];
    }
  }
}
