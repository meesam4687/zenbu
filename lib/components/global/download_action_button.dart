import 'package:flutter/material.dart';
import 'package:zenbu/components/global/pie_progress_indicator.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

class DownloadActionButton extends StatelessWidget {
  final bool isDownloading;
  final bool isDownloaded;
  final bool isPaused;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;

  const DownloadActionButton({
    super.key,
    required this.isDownloading,
    required this.isDownloaded,
    required this.isPaused,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
    required this.onPauseResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: PopupMenuButton<String>(
          tooltip: context.l10n.downloadOptions,
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'pause') {
              onPauseResume();
            } else if (value == 'cancel') {
              onCancel();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'pause',
              child: Row(
                children: [
                  Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isPaused ? context.l10n.resume : context.l10n.pause),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'cancel',
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(context.l10n.cancel),
                ],
              ),
            ),
          ],
          child: ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: PieProgressIndicator(
                  progress: progress,
                  isPaused: isPaused,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (isDownloaded) {
      return SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
          onPressed: onDelete,
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: const Icon(Icons.download_for_offline_outlined, size: 24),
        onPressed: onDownload,
      ),
    );
  }
}
