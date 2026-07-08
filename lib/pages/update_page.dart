import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zenbu/state_provider.dart';

class UpdatePage extends StatefulWidget {
  final UpdateInfo updateInfo;
  const UpdatePage({super.key, required this.updateInfo});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StateProvider>(context, listen: false)
          .checkDownloadedApk(widget.updateInfo.remoteVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<StateProvider>(context);

    final isDownloading = provider.isDownloadingUpdate &&
        provider.downloadingUpdateInfo?.remoteVersion ==
            widget.updateInfo.remoteVersion;
    final isApkDownloaded = provider.isUpdateApkDownloaded;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Update Available'),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Padding(
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
                    onPressed: provider.isDownloadingUpdate
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
                  child: isDownloading
                      ? InkWell(
                          onTap: () {
                            provider.cancelUpdateDownload();
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Ink(
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    'Stop Update',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: provider.updateDownloadProgress,
                                      minHeight: 4,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: () async {
                            if (isApkDownloaded) {
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
                            } else {
                              try {
                                await provider.startUpdateDownload(
                                  widget.updateInfo,
                                );
                              } catch (e) {
                                Fluttertoast.showToast(
                                  msg: "Failed to download update: $e",
                                  toastLength: Toast.LENGTH_LONG,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isApkDownloaded ? 'Install' : 'Download Now',
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
