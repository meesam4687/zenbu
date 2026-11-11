import 'package:flutter/material.dart';

class PaginatedHorizontalList extends StatefulWidget {
  const PaginatedHorizontalList({
    super.key,
    required this.title,
    required this.initialItems,
    required this.initialHasNextPage,
    required this.loadPage,
    required this.extractItems,
    required this.extractHasNext,
    required this.calculateHeight,
    required this.itemBuilder,
    this.topMargin = 10.0,
  });

  final String title;
  final List initialItems;
  final bool initialHasNextPage;
  final Future<Map<String, dynamic>> Function(int page) loadPage;
  final List Function(Map<String, dynamic> data) extractItems;
  final bool Function(Map<String, dynamic> data) extractHasNext;
  final double Function(BuildContext context, List items) calculateHeight;
  final Widget Function(
    BuildContext context,
    dynamic item,
    bool isFirst,
    bool isLast,
    double cardHeight,
  )
  itemBuilder;
  final double topMargin;

  @override
  State<PaginatedHorizontalList> createState() =>
      _PaginatedHorizontalListState();
}

class _PaginatedHorizontalListState extends State<PaginatedHorizontalList> {
  late List _items;
  late bool _hasMore;
  int _page = 2;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    _hasMore = widget.initialHasNextPage;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PaginatedHorizontalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialItems != widget.initialItems) {
      _items = List.from(widget.initialItems);
      _hasMore = widget.initialHasNextPage;
      _page = 2;
      _isLoading = false;
    }
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
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await widget.loadPage(_page);
      final newItems = widget.extractItems(data);
      final hasNext = widget.extractHasNext(data);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = hasNext;
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

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final double listHeight = widget.calculateHeight(context, _items);

    return Container(
      margin: EdgeInsets.only(top: widget.topMargin),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: listHeight,
            width: double.infinity,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _items.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return SizedBox(
                    width: 70,
                    height: listHeight,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                  );
                }

                final isFirst = index == 0;
                final isLast = index == _items.length - 1 && !_isLoading;

                return widget.itemBuilder(
                  context,
                  _items[index],
                  isFirst,
                  isLast,
                  listHeight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
