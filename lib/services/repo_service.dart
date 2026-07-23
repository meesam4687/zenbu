import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/mangayomi/eval/dart/service.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/service.dart';

class RepoService {
  static const String _reposKey = 'ext_repos';
  static const String _installedKey = 'ext_installed';
  static const String _sourceCodePrefix = 'ext_source_code_';

  static Future<List<ExtRepo>> getRepos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_reposKey) ?? [];
    return raw.map((e) => ExtRepo.fromJson(json.decode(e))).toList();
  }

  static Future<void> addRepo(
    String url, {
    String? customName,
    String? customWebsite,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final repos = await getRepos();

    if (repos.any((r) => r.jsonUrl == url)) {
      throw Exception('Repository already exists');
    }

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch repository list (HTTP ${res.statusCode})',
      );
    }

    final List parsed = json.decode(res.body);
    if (parsed.isEmpty || parsed.first['name'] == null) {
      throw Exception('Invalid repository index format');
    }

    String name = customName ?? 'Community Repo';
    String website = customWebsite ?? '';
    if (customName == null) {
      try {
        final match = RegExp(r'^(.*)/[^/]+\.json$').firstMatch(url);
        if (match != null) {
          final parentUrl = match.group(1)!;
          final metaRes = await http.get(Uri.parse('$parentUrl/repo.json'));
          if (metaRes.statusCode == 200) {
            final meta = json.decode(metaRes.body);
            name = meta['name'] ?? meta['meta']?['name'] ?? name;
            website = meta['website'] ?? meta['meta']?['website'] ?? website;
          }
        }
      } catch (_) {}
    }

    final newRepo = ExtRepo(name: name, website: website, jsonUrl: url);
    repos.add(newRepo);

    final rawList = repos.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_reposKey, rawList);
  }

  static Future<void> deleteRepo(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final repos = await getRepos();
    repos.removeWhere((r) => r.jsonUrl == url);
    final rawList = repos.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_reposKey, rawList);
  }

  static Future<List<ExtSource>> fetchExtensionsFromRepo(ExtRepo repo) async {
    final res = await http.get(Uri.parse(repo.jsonUrl));
    if (res.statusCode != 200) {
      return [];
    }
    final List parsed = json.decode(res.body);
    return parsed.map((e) {
      final map = Map<String, dynamic>.from(e);
      // Map itemType: 0 (manga), 1 (anime), 2 (novel)
      return ExtSource.fromJson(map);
    }).toList();
  }

  static Future<List<ExtSource>> fetchAllExtensions() async {
    final repos = await getRepos();
    final List<ExtSource> all = [];
    for (final repo in repos) {
      try {
        final extList = await fetchExtensionsFromRepo(repo);
        for (final ext in extList) {
          if (!all.any((e) => e.id == ext.id)) {
            all.add(ext);
          }
        }
      } catch (_) {}
    }
    return all;
  }

  static Future<List<ExtSource>> getInstalledExtensions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_installedKey) ?? [];
    final list = raw.map((e) => ExtSource.fromJson(json.decode(e))).toList();

    for (final ext in list) {
      ext.sourceCode = prefs.getString('$_sourceCodePrefix${ext.id}');
    }
    return list;
  }

  static Future<bool> isInstalled(int id) async {
    final installed = await getInstalledExtensions();
    return installed.any((e) => e.id == id);
  }

  static Future<void> installExtension(ExtSource source) async {
    final prefs = await SharedPreferences.getInstance();

    final res = await http.get(Uri.parse(source.sourceCodeUrl));
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to download extension source code (HTTP ${res.statusCode})',
      );
    }
    final sourceCode = res.body;

    final installed = await getInstalledExtensions();
    installed.removeWhere((e) => e.id == source.id);
    source.sourceCode = sourceCode;
    installed.add(source);

    await prefs.setString('$_sourceCodePrefix${source.id}', sourceCode);

    final rawList = installed.map((e) {
      final copy = e.toJson()..remove('sourceCode');
      return json.encode(copy);
    }).toList();
    await prefs.setStringList(_installedKey, rawList);
  }

  static Future<void> uninstallExtension(ExtSource source) async {
    final prefs = await SharedPreferences.getInstance();
    final installed = await getInstalledExtensions();
    installed.removeWhere((e) => e.id == source.id);

    await prefs.remove('$_sourceCodePrefix${source.id}');

    final rawList = installed.map((e) {
      final copy = e.toJson()..remove('sourceCode');
      return json.encode(copy);
    }).toList();
    await prefs.setStringList(_installedKey, rawList);
  }

  static Future<List<ExtSource>> cleanOrphanedExtensions(
    List<ExtSource> allExtensions,
  ) async {
    final installed = await getInstalledExtensions();
    final validInstalled = <ExtSource>[];
    for (final ext in installed) {
      if (allExtensions.any((e) => e.id == ext.id)) {
        validInstalled.add(ext);
      } else {
        await uninstallExtension(ext);
      }
    }
    return validInstalled;
  }

  static Future<ExtensionService> loadExtensionEngine(ExtSource source) async {
    final prefs = await SharedPreferences.getInstance();
    final sourceCode = prefs.getString('$_sourceCodePrefix${source.id}');
    if (sourceCode == null || sourceCode.isEmpty) {
      throw Exception(
        'Extension source code not found. Please install/re-install it.',
      );
    }

    final Map<String, dynamic> userPrefs = {};
    final prefix = 'ext_pref_${source.id}_';
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        final prefKey = key.substring(prefix.length);
        final rawVal = prefs.getString(key);
        if (rawVal != null) {
          try {
            userPrefs[prefKey] = json.decode(rawVal);
          } catch (_) {}
        }
      }
    }

    final mSource = Source(
      id: source.id,
      name: source.name,
      baseUrl: source.baseUrl,
      lang: source.lang,
      isNsfw: source.isNsfw,
      sourceCode: sourceCode,
      sourceCodeUrl: source.sourceCodeUrl,
      iconUrl: source.iconUrl,
      isManga: source.isManga,
      apiUrl: source.apiUrl,
      dateFormat: source.dateFormat,
      dateFormatLocale: source.dateFormatLocale,
      version: source.version,
      sourceCodeLanguage:
          (source.sourceCodeLanguage == 0 ||
              source.sourceCodeUrl
                  .toLowerCase()
                  .split('?')
                  .first
                  .endsWith('.dart'))
          ? SourceCodeLanguage.dart
          : SourceCodeLanguage.javascript,
    );

    if (mSource.sourceCodeLanguage == SourceCodeLanguage.dart) {
      return DartExtensionService(mSource);
    } else {
      return JsExtensionService(mSource, userPrefs: userPrefs);
    }
  }

  static Future<List<dynamic>> getExtensionPreferences(ExtSource source) async {
    final service = await loadExtensionEngine(source);
    try {
      final prefs = service.getSourcePreferences();
      return prefs.map((e) => e.toJson()).toList();
    } finally {
      service.dispose();
    }
  }
}
