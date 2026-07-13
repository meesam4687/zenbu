import 'package:flutter/material.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/download_service.dart';
import 'package:zenbu/pages/video_player_page.dart';
import 'package:zenbu/pages/manga_reader_page.dart';
import 'package:zenbu/components/global/custom_image.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _downloadService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Anime'),
              Tab(text: 'Manga'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildMediaList(false), _buildMediaList(true)],
        ),
      ),
    );
  }

  Widget _buildMediaList(bool isManga) {
    final list = isManga
        ? _downloadService.mangaRegistry
        : _downloadService.animeRegistry;
    final activeKeys = _downloadService.activeDownloads.keys
        .where((url) => _downloadService.activeTypes[url] == isManga)
        .toList();

    if (list.isEmpty && activeKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isManga ? Icons.book_outlined : Icons.movie_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No downloaded ${isManga ? "manga" : "anime"} found.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      children: [
        if (activeKeys.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Downloading (${activeKeys.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...activeKeys.map((url) {
            final name = _downloadService.activeNames[url] ?? 'Downloading...';
            final mediaTitle = _downloadService.activeMediaTitles[url] ?? '';
            final progress = _downloadService.activeDownloads[url] ?? 0.0;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).colorScheme.onInverseSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  '$mediaTitle - $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: LinearProgressIndicator(
                        value: (progress == 0.0) ? null : progress,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          progress == 0.0
                              ? 'Resolving...'
                              : '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _downloadService.getDownloadSpeed(url),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () =>
                      _downloadService.cancelDownload(isManga, url),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
        ],
        ...list.map((media) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Theme.of(context).colorScheme.onInverseSurface,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DownloadedItemsListPage(media: media),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 75,
                        child: media.coverImage.isNotEmpty
                            ? CustomImage(
                                imageUrl: media.coverImage,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                child: const Icon(Icons.broken_image, size: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            media.mediaTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${media.items.length} downloaded ${isManga ? "chapter" : "episode"}${media.items.length == 1 ? "" : "s"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class DownloadedItemsListPage extends StatefulWidget {
  final DownloadedMedia media;

  const DownloadedItemsListPage({super.key, required this.media});

  @override
  State<DownloadedItemsListPage> createState() =>
      _DownloadedItemsListPageState();
}

class _DownloadedItemsListPageState extends State<DownloadedItemsListPage> {
  final _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _downloadService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.media.isManga
        ? _downloadService.mangaRegistry
        : _downloadService.animeRegistry;
    final mediaIdx = registry.indexWhere(
      (e) => e.mediaId == widget.media.mediaId,
    );

    if (mediaIdx == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox());
    }

    final media = registry[mediaIdx];

    return Scaffold(
      appBar: AppBar(title: Text(media.mediaTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: media.items.length,
        itemBuilder: (context, index) {
          final item = media.items[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Theme.of(context).colorScheme.onInverseSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Download'),
                      content: Text(
                        'Are you sure you want to delete ${item.name}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _downloadService.deleteDownloadedItem(
                      media.isManga,
                      item.url,
                    );
                  }
                },
              ),
              onTap: () {
                if (media.isManga) {
                  final localSource = ExtSource(
                    id: -1,
                    name: 'Local Source',
                    baseUrl: '',
                    lang: 'all',
                    version: '1.0.0',
                    sourceCodeUrl: '',
                    iconUrl: '',
                    isNsfw: false,
                    isManga: true,
                  );

                  final chapters = media.items
                      .map((e) => ExtEpisode(name: e.name, url: e.localPath))
                      .toList();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MangaReaderPage(
                        chapters: chapters,
                        currentIndex: index,
                        source: localSource,
                        mangaTitle: media.mediaTitle,
                        mediaId: media.mediaId,
                        coverImage: media.coverImage,
                      ),
                    ),
                  );
                } else {
                  final localSource = ExtSource(
                    id: -1,
                    name: 'Local Source',
                    baseUrl: '',
                    lang: 'all',
                    version: '1.0.0',
                    sourceCodeUrl: '',
                    iconUrl: '',
                    isNsfw: false,
                    isManga: false,
                  );

                  final ep = ExtEpisode(name: item.name, url: item.localPath);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerPage(
                        episode: ep,
                        source: localSource,
                        animeTitle: media.mediaTitle,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
