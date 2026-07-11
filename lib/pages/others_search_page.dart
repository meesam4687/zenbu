import 'package:flutter/material.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/services/anilist/anilist.dart';

class OthersSearchPage extends StatefulWidget {
  const OthersSearchPage({super.key, required this.type, required this.query});

  final String type;
  final String query;

  @override
  State<OthersSearchPage> createState() => _OthersSearchPageState();
}

class _OthersSearchPageState extends State<OthersSearchPage> {
  final List<dynamic> _results = [];
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _textController;

  late String _currentQuery;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
    _textController = TextEditingController(text: _currentQuery);
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (!_hasMore || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      dynamic data;
      List<dynamic> fetchedList = [];

      if (widget.type == 'character') {
        data = await searchCharacters(_page, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["characters"] ?? [];
      } else if (widget.type == 'staff') {
        data = await searchStaff(_page, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["staff"] ?? [];
      } else if (widget.type == 'studio') {
        data = await searchStudios(_page, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["studios"] ?? [];
      } else if (widget.type == 'user') {
        data = await searchUsers(_page, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["users"] ?? [];
      }

      if (mounted) {
        setState(() {
          _results.addAll(fetchedList);
          if (fetchedList.length < 48) {
            _hasMore = false;
          }
          _page++;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _triggerNewSearch(String query) {
    if (query.trim().isEmpty || query == _currentQuery) return;
    setState(() {
      _currentQuery = query;
      _results.clear();
      _page = 1;
      _hasMore = true;
    });
    _loadMore();
  }

  Future<void> _handleRefresh() async {
    try {
      dynamic data;
      List<dynamic> fetchedList = [];

      if (widget.type == 'character') {
        data = await searchCharacters(1, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["characters"] ?? [];
      } else if (widget.type == 'staff') {
        data = await searchStaff(1, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["staff"] ?? [];
      } else if (widget.type == 'studio') {
        data = await searchStudios(1, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["studios"] ?? [];
      } else if (widget.type == 'user') {
        data = await searchUsers(1, 48, _currentQuery);
        fetchedList = data?["data"]?["Page"]?["users"] ?? [];
      }

      if (mounted) {
        setState(() {
          _results.clear();
          _results.addAll(fetchedList);
          _page = 2;
          _hasMore = fetchedList.length >= 48;
        });
      }
    } catch (_) {}
  }

  String _getItemTitle(dynamic item) {
    if (widget.type == 'character' || widget.type == 'staff') {
      return item["name"]?["full"] ?? "Unknown Name";
    } else if (widget.type == 'studio') {
      return item["name"] ?? "Unknown Studio";
    } else if (widget.type == 'user') {
      return item["name"] ?? "Unknown User";
    }
    return "";
  }

  String? _getItemImage(dynamic item) {
    if (widget.type == 'character' || widget.type == 'staff') {
      return item["image"]?["large"];
    } else if (widget.type == 'user') {
      return item["avatar"]?["large"];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: 12.0,
        title: Container(
          margin: EdgeInsets.only(left: 4, right: 4),
          height: 40.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.onInverseSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(80),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: _triggerNewSearch,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: (_results.isEmpty && _isLoading)
            ? const Center(child: CircularProgressIndicator.adaptive())
            : (_results.isNotEmpty)
            ? Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  gridDelegate: const ConstantSliverGridDelegate(
                    itemWidth: 110.0,
                    itemHeight: 226.0,
                  ),
                  itemCount: _isLoading ? _results.length + 1 : _results.length,
                  itemBuilder: (context, index) {
                    if (index == _results.length && _isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }
                    final item = _results[index];
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: ItemCard(
                          title: _getItemTitle(item),
                          image: _getItemImage(item),
                          id: item["id"] as int,
                          type: widget.type,
                        ),
                      ),
                    );
                  },
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Text(
                      "No Results",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
