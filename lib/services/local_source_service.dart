import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalSourceService {
  static const String _localDirectoryKey = 'local_directory_path';

  static String sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<bool> checkAndRequestStoragePermission(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return true;

    try {
      try {
        await Permission.notification.request();
      } catch (_) {}

      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;

      if (!context.mounted) return false;
      final bool? grantPressed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('All Files Access Required'),
          content: const Text(
            'To play local videos and read local manga chapters/archives from external directories on Android 11+, Zenbu requires "All Files Access" permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );

      if (grantPressed == true) {
        final requestStatus = await Permission.manageExternalStorage.request();
        return requestStatus.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('[PERMISSION ERROR] $e');
      return true;
    }
  }

  static Future<String?> pickRootDirectory(BuildContext context) async {
    if (!await checkAndRequestStoragePermission(context)) return null;
    try {
      final String? selectedDirectory = await getDirectoryPath();
      if (selectedDirectory != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localDirectoryKey, selectedDirectory);
        return selectedDirectory;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick directory: $e')));
      }
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> scanAnime({
    required String animeTitle,
    required String? customLink,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final directoryPath = prefs.getString(_localDirectoryKey);
    if (directoryPath == null || directoryPath.isEmpty) {
      throw Exception('Local directory is not configured.');
    }

    final animeRootPath =
        '$directoryPath${Platform.isWindows ? '\\' : '/'}anime';
    final animeRootDir = Directory(animeRootPath);
    if (!await animeRootDir.exists()) {
      await animeRootDir.create(recursive: true);
    }

    String? matchedFolderPath;
    if (customLink != null && customLink.isNotEmpty) {
      matchedFolderPath = customLink;
    } else {
      final List<FileSystemEntity> entities = animeRootDir.listSync();
      final titleLower = animeTitle.toLowerCase();
      final sanitizedTitleLower = sanitizeFilename(animeTitle).toLowerCase();
      for (final entity in entities) {
        if (entity is Directory) {
          final folderName = entity.path
              .split(Platform.isWindows ? '\\' : '/')
              .last
              .toLowerCase();
          if (folderName == titleLower ||
              folderName == sanitizedTitleLower ||
              titleLower.contains(folderName) ||
              sanitizedTitleLower.contains(folderName)) {
            matchedFolderPath = entity.path;
            break;
          }
        }
      }
    }

    if (matchedFolderPath == null || matchedFolderPath.isEmpty) {
      throw Exception('No matching anime folder found.');
    }

    final animeDir = Directory(matchedFolderPath);
    if (!await animeDir.exists()) {
      throw Exception('Anime folder does not exist.');
    }

    final List<FileSystemEntity> epEntities = animeDir.listSync(
      recursive: true,
    );

    final List<Map<String, dynamic>> rawEpisodes = [];
    final videoExtensions = ['.mp4', '.mkv', '.webm', '.avi', '.mov'];

    final videoFiles = epEntities.whereType<File>().where((file) {
      final nameLower = file.path.toLowerCase();
      return videoExtensions.any((ext) => nameLower.endsWith(ext));
    }).toList();

    videoFiles.sort((a, b) => a.path.compareTo(b.path));

    for (final file in videoFiles) {
      final epName = file.path.split(Platform.isWindows ? '\\' : '/').last;
      rawEpisodes.add({'name': epName, 'url': file.path});
    }

    return rawEpisodes;
  }

  static Future<List<Map<String, dynamic>>> scanManga({
    required String mangaTitle,
    required String? customLink,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final directoryPath = prefs.getString(_localDirectoryKey);
    if (directoryPath == null || directoryPath.isEmpty) {
      throw Exception('Local directory is not configured.');
    }

    final mangaRootPath =
        '$directoryPath${Platform.isWindows ? '\\' : '/'}manga';
    final mangaRootDir = Directory(mangaRootPath);
    if (!await mangaRootDir.exists()) {
      await mangaRootDir.create(recursive: true);
    }

    String? matchedFolderPath;
    if (customLink != null && customLink.isNotEmpty) {
      matchedFolderPath = customLink;
    } else {
      final List<FileSystemEntity> entities = mangaRootDir.listSync();
      final titleLower = mangaTitle.toLowerCase();
      final sanitizedTitleLower = sanitizeFilename(mangaTitle).toLowerCase();
      for (final entity in entities) {
        if (entity is Directory) {
          final folderName = entity.path
              .split(Platform.isWindows ? '\\' : '/')
              .last
              .toLowerCase();
          if (folderName == titleLower ||
              folderName == sanitizedTitleLower ||
              titleLower.contains(folderName) ||
              sanitizedTitleLower.contains(folderName)) {
            matchedFolderPath = entity.path;
            break;
          }
        }
      }
    }

    if (matchedFolderPath == null || matchedFolderPath.isEmpty) {
      throw Exception('No matching manga folder found.');
    }

    final mangaDir = Directory(matchedFolderPath);
    if (!await mangaDir.exists()) {
      throw Exception('Manga folder does not exist.');
    }

    final List<FileSystemEntity> chapEntities = mangaDir.listSync();

    final List<Map<String, dynamic>> rawChapters = [];

    final subfolders = chapEntities.whereType<Directory>().toList();
    final archives = chapEntities.whereType<File>().where((file) {
      final nameLower = file.path.toLowerCase();
      return nameLower.endsWith('.zip') || nameLower.endsWith('.cbz');
    }).toList();

    subfolders.sort((a, b) => a.path.compareTo(b.path));
    archives.sort((a, b) => a.path.compareTo(b.path));

    for (final dir in subfolders) {
      final folderName = dir.path.split(Platform.isWindows ? '\\' : '/').last;
      rawChapters.add({'name': folderName, 'url': dir.path});
    }

    for (final file in archives) {
      final fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;
      rawChapters.add({'name': fileName, 'url': file.path});
    }

    return rawChapters.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> searchLocalFolders({
    required String query,
    required bool isManga,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final directoryPath = prefs.getString(_localDirectoryKey);
    if (directoryPath == null || directoryPath.isEmpty) {
      throw Exception('Local directory is not configured.');
    }

    final subfolderName = isManga ? 'manga' : 'anime';
    final subfolderPath =
        '$directoryPath${Platform.isWindows ? '\\' : '/'}$subfolderName';
    final subfolderDir = Directory(subfolderPath);
    if (!await subfolderDir.exists()) {
      await subfolderDir.create(recursive: true);
    }

    final List<FileSystemEntity> entities = subfolderDir.listSync();
    final List<Map<String, dynamic>> localResults = [];
    final queryLower = query.toLowerCase();

    for (final entity in entities) {
      if (entity is Directory) {
        final folderName = entity.path
            .split(Platform.isWindows ? '\\' : '/')
            .last;
        if (query.isEmpty || folderName.toLowerCase().contains(queryLower)) {
          String coverPath = '';
          final possibleCovers = [
            'cover.jpg',
            'cover.png',
            'cover.jpeg',
            'folder.jpg',
            'folder.png',
          ];
          for (final coverName in possibleCovers) {
            final file = File('${entity.path}/$coverName');
            if (await file.exists()) {
              coverPath = file.path;
              break;
            }
          }

          localResults.add({
            'name': folderName,
            'link': entity.path,
            'cover': coverPath,
          });
        }
      }
    }

    return localResults;
  }
}
