import 'package:flutter/material.dart';
import 'package:zenbu/services/anilist/get_user_profile.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/components/user_profile_page/profile_stats_tab.dart';
import 'package:zenbu/pages/error_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, this.username, this.userId});

  final String? username;
  final int? userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profileFuture = getUserProfile(name: widget.username, id: widget.userId);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildHeader(
    BuildContext context,
    String? bannerImage,
    String avatarUrl,
  ) {
    final theme = Theme.of(context);
    const bannerHeight = 160.0;
    const avatarSize = 100.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: bannerHeight,
          width: double.infinity,
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
          child: bannerImage != null
              ? CustomImage(
                  imageUrl: bannerImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: bannerHeight,
                  borderRadius: BorderRadius.zero,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: bannerHeight - (avatarSize / 2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.scaffoldBackgroundColor,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: CustomImage(
                imageUrl: avatarUrl,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.username ?? 'User Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return ErrorPage(
              scaffold: false,
              message: snapshot.error.toString(),
              onReload: () {
                setState(() {
                  _profileFuture = getUserProfile(
                    name: widget.username,
                    id: widget.userId,
                  );
                });
              },
            );
          }

          final user = snapshot.data?['data']?['User'];
          if (user == null) {
            return ErrorPage(
              scaffold: false,
              message: 'User not found on AniList',
              onReload: () {
                setState(() {
                  _profileFuture = getUserProfile(
                    name: widget.username,
                    id: widget.userId,
                  );
                });
              },
            );
          }

          final bannerImage = user['bannerImage'] as String?;
          final avatarUrl = user['avatar']?['large'] as String? ?? '';
          final username = user['name'] as String? ?? 'Unknown';
          final statistics = user['statistics'] ?? {};
          final animeStats = statistics['anime'] ?? {};
          final mangaStats = statistics['manga'] ?? {};

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, bannerImage, avatarUrl),
                      const SizedBox(height: 55),
                      Center(
                        child: Text(
                          username,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Anime'),
                          Tab(text: 'Manga'),
                        ],
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _KeepAliveWrapper(
                  child: SingleChildScrollView(
                    key: const PageStorageKey('user_anime_stats'),
                    physics: const ClampingScrollPhysics(),
                    child: ProfileStatsTab(
                      statistics: animeStats,
                      isAnime: true,
                    ),
                  ),
                ),
                _KeepAliveWrapper(
                  child: SingleChildScrollView(
                    key: const PageStorageKey('user_manga_stats'),
                    physics: const ClampingScrollPhysics(),
                    child: ProfileStatsTab(
                      statistics: mangaStats,
                      isAnime: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
