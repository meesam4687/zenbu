import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenbu/services/download_service.dart';

class VideoPlayerErrorView extends StatelessWidget {
  final bool playerFailed;
  final String? errorMessage;
  final bool isLocalSource;
  final String episodeUrl;
  final VoidCallback onRetry;

  const VideoPlayerErrorView({
    super.key,
    required this.playerFailed,
    required this.errorMessage,
    required this.isLocalSource,
    required this.episodeUrl,
    required this.onRetry,
  });

  Future<void> _goBack(BuildContext context) async {
    final navigator = Navigator.of(context);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (playerFailed) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Playback Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () => _goBack(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (isLocalSource) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      await DownloadService().deleteDownloadedItem(
                        false,
                        episodeUrl,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Download'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () => _goBack(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
