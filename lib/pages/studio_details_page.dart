import 'package:flutter/material.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:zenbu/services/anilist/get_studio_data.dart';

class StudioDetailsPage extends StatefulWidget {
  const StudioDetailsPage({super.key, required this.studioId, this.studioName});

  final int studioId;
  final String? studioName;

  @override
  State<StudioDetailsPage> createState() => _StudioDetailsPageState();
}

class _StudioDetailsPageState extends State<StudioDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _medias = [];
  bool _isLoading = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String? _errorMessage;
  String? _resolvedStudioName;

  @override
  void initState() {
    super.initState();
    _resolvedStudioName = widget.studioName;
    _fetchMedias();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasNextPage) {
        _fetchMedias();
      }
    }
  }

  Future<void> _fetchMedias({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasNextPage = true;
        _medias.clear();
        _errorMessage = null;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await getStudioData(
        id: widget.studioId,
        page: _currentPage,
        perPage: 20,
      );

      final studioData = res['data']?['Studio'];
      if (studioData != null) {
        final String? name = studioData['name'] as String?;
        final mediaData = studioData['media'];
        final pageInfo = mediaData?['pageInfo'];
        final List? nodes = mediaData?['nodes'] as List?;

        setState(() {
          if (name != null && _resolvedStudioName == null) {
            _resolvedStudioName = name;
          }
          if (nodes != null) {
            for (final n in nodes) {
              if (n is Map<String, dynamic>) {
                _medias.add(n);
              }
            }
          }
          if (pageInfo != null) {
            _hasNextPage = pageInfo['hasNextPage'] as bool? ?? false;
            _currentPage =
                (pageInfo['currentPage'] as int? ?? _currentPage) + 1;
          } else {
            _hasNextPage = false;
          }
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Studio details not found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchMedias(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ErrorPage(
        scaffold: true,
        message: _errorMessage,
        onReload: () => _fetchMedias(refresh: true),
      );
    }

    final title = _resolvedStudioName ?? "Studio Details";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _medias.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  gridDelegate: const ConstantSliverGridDelegate(
                    itemWidth: 110.0,
                    itemHeight: 226.0,
                  ),
                  itemCount: _isLoading ? _medias.length + 1 : _medias.length,
                  itemBuilder: (context, index) {
                    if (index == _medias.length && _isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final media = _medias[index];

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: ItemCard(
                          title:
                              media['title']?['userPreferred'] as String? ??
                              'Unknown',
                          image: media['coverImage']?['large'] as String? ?? '',
                          id: media['id'] as int,
                          type: 'anime',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
