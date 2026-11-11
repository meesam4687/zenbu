import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/state_provider.dart';

class ListPageView extends StatefulWidget {
  const ListPageView({
    super.key,
    required this.mediaType,
    this.userId,
    this.status,
    this.isFavourites = false,
    this.searchQuery = "",
    this.searchResults,
    this.isSearching = false,
  });

  final String mediaType;
  final int? userId;
  final String? status;
  final bool isFavourites;
  final String searchQuery;
  final List? searchResults;
  final bool isSearching;

  @override
  State<ListPageView> createState() => _ListPageViewState();
}

class _ListPageViewState extends State<ListPageView>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _medias = [];
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore &&
        !widget.isSearching) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> newItems = [];
      bool hasNext = false;

      if (widget.isFavourites) {
        final data = await getFavourites(
          page: _page,
          perPage: 25,
          type: widget.mediaType,
          userId: widget.userId,
        );

        final mediaKey = widget.mediaType.toLowerCase() == "manga"
            ? "manga"
            : "anime";
        final favData = data["data"]?["User"]?["favourites"]?[mediaKey];
        final nodes = (favData?["nodes"] as List?) ?? [];
        hasNext = favData?["pageInfo"]?["hasNextPage"] as bool? ?? false;

        for (final node in nodes) {
          if (node is Map) {
            newItems.add({"media": Map<String, dynamic>.from(node)});
          }
        }
      } else {
        final data = await getMediaList(
          page: _page,
          perPage: 48,
          type: widget.mediaType,
          userId: widget.userId,
          status: widget.status,
        );

        final pageData = data["data"]?["Page"];
        final list = (pageData?["mediaList"] as List?) ?? [];
        hasNext = pageData?["pageInfo"]?["hasNextPage"] as bool? ?? false;

        for (final item in list) {
          if (item is Map) {
            final mediaData = item["media"];
            if (mediaData is Map) {
              final Map<String, dynamic> mediaCopy = Map<String, dynamic>.from(
                mediaData,
              );
              mediaCopy["mediaListEntry"] ??= {
                "id": item["id"],
                "status": item["status"],
                "score": item["score"],
                "progress": item["progress"],
                "repeat": item["repeat"],
                "startedAt": item["startedAt"],
                "completedAt": item["completedAt"],
              };
              newItems.add({"id": item["id"], "media": mediaCopy});
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _medias.addAll(newItems);
          _hasMore = hasNext;
          _page++;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _hasMore &&
              !_isLoading &&
              _scrollController.hasClients) {
            if (_scrollController.position.maxScrollExtent <= 100) {
              _loadMore();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _medias.clear();
      _page = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    await _loadMore();
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.mediaType == "anime"
                    ? Icons.tv_off_outlined
                    : Icons.menu_book_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.emptyList,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _errorMessage ?? context.l10n.unknownGraphQLError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<StateProvider>(context);

    final displayList = widget.isSearching
        ? (widget.searchResults ?? const [])
        : _medias;

    if (_errorMessage != null && _medias.isEmpty && !widget.isSearching) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildErrorState(context),
      );
    }

    if (displayList.isEmpty && !_isLoading) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildEmptyState(context),
      );
    }

    if (displayList.isEmpty && _isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  gridDelegate: const ConstantSliverGridDelegate(
                    itemWidth: 110.0,
                    itemHeight: 226.0,
                  ),
                  itemCount: (_isLoading && !widget.isSearching)
                      ? displayList.length + 1
                      : displayList.length,
                  itemBuilder: (context, index) {
                    if (index == displayList.length &&
                        _isLoading &&
                        !widget.isSearching) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final item = displayList[index];
                    final media = item["media"] as Map? ?? {};
                    final titleMap = media["title"] as Map?;
                    final coverImage = media["coverImage"] as Map?;
                    final imageUrl =
                        (coverImage?["extraLarge"] ?? coverImage?["large"])
                            as String?;
                    final mediaId = media["id"] as int? ?? 0;
                    final mediaListEntry = media["mediaListEntry"] as Map?;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: ItemCard(
                          title: provider.resolveTitle(titleMap),
                          image: imageUrl,
                          id: mediaId,
                          type: widget.mediaType,
                          mediaListEntry: mediaListEntry,
                          listDataPreloaded: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
