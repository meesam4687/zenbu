import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class UpdatePage extends StatefulWidget {
  final UpdateInfo updateInfo;
  const UpdatePage({super.key, required this.updateInfo});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isApkDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkIfApkDownloaded();
  }

  Future<void> _checkIfApkDownloaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedVersion = prefs.getString('downloaded_apk_version');
      if (downloadedVersion == widget.updateInfo.remoteVersion) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/app-release.apk');
        if (await file.exists()) {
          setState(() {
            _isApkDownloaded = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _startDownload() async {
    if (_isApkDownloaded) {
      try {
        await UpdateService.installCachedApk();
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to install update: $e",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await UpdateService.downloadAndInstallApk(
        downloadUrl: widget.updateInfo.downloadUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'downloaded_apk_version',
        widget.updateInfo.remoteVersion,
      );
      if (mounted) {
        setState(() {
          _isApkDownloaded = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to download update: $e",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Update Available'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.system_update,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'A new version is available!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version: ${widget.updateInfo.remoteVersion}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Markdown(
                      data: widget.updateInfo.changelog,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium,
                        h1: theme.textTheme.titleLarge,
                        h2: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isDownloading
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await UpdateService.markAsIgnore(
                                  widget.updateInfo.remoteVersion,
                                );
                                navigator.pop();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Download Later'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isDownloading ? null : _startDownload,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _isApkDownloaded ? 'Install' : 'Download Now',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Downloading Update...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
