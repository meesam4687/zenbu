import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:zenbu/pages/review_page.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/custom_image.dart';

class ReviewsPane extends StatefulWidget {
  const ReviewsPane({super.key, required this.mediaId});

  final int mediaId;

  @override
  State<ReviewsPane> createState() => _ReviewsPaneState();
}

class _ReviewsPaneState extends State<ReviewsPane> {
  final List<Map> _reviews = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await getMediaReviews(widget.mediaId, _page, 10);
      final list = data["data"]?["Media"]?["reviews"]?["nodes"] as List?;

      setState(() {
        if (list != null && list.isNotEmpty) {
          for (var item in list) {
            if (item != null && item.isNotEmpty) {
              _reviews.add(item);
            }
          }
          _page++;
          if (list.length < 10) {
            _hasMore = false;
          }
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final data = await getMediaReviews(widget.mediaId, 1, 10);
      final list = data["data"]?["Media"]?["reviews"]?["nodes"] as List?;

      if (mounted) {
        setState(() {
          _reviews.clear();
          if (list != null && list.isNotEmpty) {
            for (var item in list) {
              if (item != null && item.isNotEmpty) {
                _reviews.add(item);
              }
            }
            _page = 2;
            _hasMore = list.length >= 10;
          } else {
            _hasMore = false;
          }
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _reload() {
    setState(() {
      _reviews.clear();
      _page = 1;
      _hasMore = true;
      _hasError = false;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(child: Error(reload: _reload)),
          ),
        ),
      );
    }

    if (_reviews.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Text(
                "No reviews available for this media.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: _isLoading && _hasMore
            ? _reviews.length + 1
            : _reviews.length,
        itemBuilder: (context, index) {
          if (index == _reviews.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final review = _reviews[index];
          final summary = review["summary"] ?? "";
          final body = review["body"] ?? "";
          final score = review["score"] ?? 0;
          final user = review["user"];
          final username = user?["name"] as String?;
          final avatarUrl = user?["avatar"]?["large"] as String?;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: OpenContainer(
              closedElevation: 2,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              closedColor: Theme.of(context).colorScheme.onInverseSurface,
              openColor: Theme.of(context).scaffoldBackgroundColor,
              closedBuilder: (context, action) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    action();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (avatarUrl != null) ...[
                              CustomImage(
                                imageUrl: avatarUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(360),
                                errorWidget: const Icon(
                                  Icons.account_circle,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                username ?? "Anonymous",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
              openBuilder: (context, action) {
                return ReviewPage(
                  summary: summary,
                  body: body,
                  score: score,
                  username: username,
                  avatarUrl: avatarUrl,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
