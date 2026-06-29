import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart';

class UpdateInfo {
  final String remoteVersion;
  final String changelog;
  final String downloadUrl;

  UpdateInfo({
    required this.remoteVersion,
    required this.changelog,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const _pipChannel = MethodChannel('zenbu/pip');

  static Future<UpdateInfo?> checkUpdate({bool force = false}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/meesam4687/zenbu/refs/heads/main/pubspec.yaml',
        ),
      );
      if (response.statusCode != 200) return null;

      final doc = loadYaml(response.body);
      final remoteVersionStr = doc['version'] as String?;
      if (remoteVersionStr == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersionName = packageInfo.version;
      final localVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final remoteParts = remoteVersionStr.split('+');
      final remoteVersionName = remoteParts[0];
      final remoteVersionCode = remoteParts.length > 1
          ? int.tryParse(remoteParts[1]) ?? 0
          : 0;

      final bool hasNameChange = remoteVersionName != localVersionName;
      final bool hasCodeIncrement = remoteVersionCode > localVersionCode;
      final bool isUpdateAvailable = hasNameChange || hasCodeIncrement;

      if (!isUpdateAvailable) return null;

      final prefs = await SharedPreferences.getInstance();
      final ignoredVersion = prefs.getString('update_later_version');
      if (!force && ignoredVersion == remoteVersionStr) {
        return null;
      }

      final releaseResponse = await http.get(
        Uri.parse(
          'https://api.github.com/repos/meesam4687/zenbu/releases/latest',
        ),
      );
      if (releaseResponse.statusCode != 200) {
        final fallbackDownloadUrl =
            'https://github.com/meesam4687/zenbu/releases/download/v$remoteVersionStr/app-release.apk';
        return UpdateInfo(
          remoteVersion: remoteVersionStr,
          changelog: 'No release notes available.',
          downloadUrl: fallbackDownloadUrl,
        );
      }

      final releaseJson =
          json.decode(releaseResponse.body) as Map<String, dynamic>;
      final changelog =
          releaseJson['body'] as String? ?? 'No release notes available.';
      final tagName =
          releaseJson['tag_name'] as String? ?? 'v$remoteVersionStr';

      String downloadUrl = '';
      final assets = releaseJson['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name'] as String?;
          if (name != null && name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            break;
          }
        }
      }

      if (downloadUrl.isEmpty) {
        downloadUrl =
            'https://github.com/meesam4687/zenbu/releases/download/$tagName/app-release.apk';
      }

      return UpdateInfo(
        remoteVersion: remoteVersionStr,
        changelog: changelog,
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndInstallApk({
    required String downloadUrl,
    required Function(double progress) onProgress,
  }) async {
    final client = http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download update: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final cacheDir = await getTemporaryDirectory();
      final apkFile = File('${cacheDir.path}/app-release.apk');
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      sink = apkFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0) {
          onProgress(downloadedBytes / contentLength);
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;

      await _pipChannel.invokeMethod('installApk', {'path': apkFile.path});
    } catch (e) {
      if (sink != null) {
        await sink.close();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<void> installCachedApk() async {
    final cacheDir = await getTemporaryDirectory();
    final apkFile = File('${cacheDir.path}/app-release.apk');
    if (await apkFile.exists()) {
      await _pipChannel.invokeMethod('installApk', {'path': apkFile.path});
    }
  }

  static Future<void> markAsIgnore(String versionStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('update_later_version', versionStr);
  }
}
