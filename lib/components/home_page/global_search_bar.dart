import 'package:flutter/material.dart';
import 'package:zenbu/pages/media_search_page.dart';
import 'package:zenbu/pages/others_search_page.dart';

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key, required this.onSearchStateChanged});

  final ValueChanged<bool> onSearchStateChanged;

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _showOverlay() {
    _hideOverlay();
    if (!mounted) return;

    final double expandedWidth = MediaQuery.of(context).size.width - 128;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: expandedWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: TapRegion(
              groupId: 'search_group',
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withAlpha(80),
                color: Theme.of(context).colorScheme.onInverseSurface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    final query = value.text.trim();
                    if (query.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Type to search...',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOverlayOption(
                          icon: Icons.video_library,
                          label: 'Search Anime for "$query"',
                          onTap: () => _navigate('anime', query),
                        ),
                        _buildOverlayOption(
                          icon: Icons.menu_book,
                          label: 'Search Manga for "$query"',
                          onTap: () => _navigate('manga', query),
                        ),
                        _buildOverlayOption(
                          icon: Icons.person,
                          label: 'Search Characters for "$query"',
                          onTap: () => _navigate('character', query),
                        ),
                        _buildOverlayOption(
                          icon: Icons.brush,
                          label: 'Search Staff for "$query"',
                          onTap: () => _navigate('staff', query),
                        ),
                        _buildOverlayOption(
                          icon: Icons.business,
                          label: 'Search Studios for "$query"',
                          onTap: () => _navigate('studio', query),
                        ),
                        _buildOverlayOption(
                          icon: Icons.people,
                          label: 'Search Users for "$query"',
                          onTap: () => _navigate('user', query),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(String type, String query) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    widget.onSearchStateChanged(false);
    _hideOverlay();
    _searchFocusNode.unfocus();

    if (type == 'anime' || type == 'manga') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SearchPage(isAnime: type == 'anime', query: query),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OthersSearchPage(type: type, query: query),
        ),
      );
    }
  }

  void _onSearchTapped() {
    setState(() {
      _isSearching = !_isSearching;
      widget.onSearchStateChanged(_isSearching);
      if (_isSearching) {
        _searchFocusNode.requestFocus();
        _showOverlay();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double expandedWidth = MediaQuery.of(context).size.width - 128;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: 'search_group',
        onTapOutside: (event) {
          if (_isSearching) {
            _onSearchTapped();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          width: _isSearching ? expandedWidth : 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: _isSearching
                ? Theme.of(context).colorScheme.onInverseSurface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: _isSearching
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.onSecondary,
                    width: 1,
                  ),
            boxShadow: _isSearching
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _isSearching
                ? Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _onSearchTapped,
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.search),
                    onPressed: _onSearchTapped,
                  ),
          ),
        ),
      ),
    );
  }
}
