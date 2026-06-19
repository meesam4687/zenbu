import 'package:provider/provider.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/notification_page/notification_card.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/state_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map> items = [];
  int page = 1;
  int _unreadCount = 0;
  bool _clearedUnread = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      Map data = await getNotifications(page, 10);
      setState(() {
        for (var item in (data["data"]["Page"]["notifications"] as List)) {
          if (item.isNotEmpty) {
            items.add(item);
          }
        }
        page++;
        _isLoading = false;
      });

      if (!_clearedUnread && mounted) {
        final viewer = Provider.of<StateProvider>(
          context,
          listen: false,
        ).alData["data"]?["Viewer"];
        if (viewer != null && viewer["unreadNotificationCount"] != null) {
          _unreadCount = viewer["unreadNotificationCount"];
        }
        Provider.of<StateProvider>(context, listen: false).clearNotifications();
        _clearedUnread = true;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _reload() {
    setState(() {
      items.clear();
      page = 1;
      _hasError = false;
    });
    _loadMore();
  }

  Future<void> _handleRefresh() async {
    try {
      Map data = await getNotifications(1, 10);
      if (mounted) {
        setState(() {
          items.clear();
          for (var item in (data["data"]["Page"]["notifications"] as List)) {
            if (item.isNotEmpty) {
              items.add(item);
            }
          }
          page = 2;
          _unreadCount = 0;
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _hasError
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 120,
                  child: Center(child: Error(reload: _reload)),
                ),
              )
            : (items.isEmpty)
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              childAspectRatio: 16 / 9,
                              maxCrossAxisExtent: 400,
                            ),
                        itemCount: _isLoading ? items.length + 1 : items.length,
                        itemBuilder: (context, index) {
                          if (index == items.length && _isLoading == true) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return NotificationCard(
                            notificationData: items[index],
                            isUnread: index < _unreadCount,
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
