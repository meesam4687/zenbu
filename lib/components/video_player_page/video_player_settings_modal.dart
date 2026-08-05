import 'package:flutter/material.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';

enum _SettingsSubMenu { main, quality, subtitles, speed }

class VideoPlayerSettingsModal extends StatefulWidget {
  final List<ExtVideo> videos;
  final ExtVideo? selectedVideo;
  final ValueChanged<ExtVideo> onQualitySelected;

  final List<ExtSubtitle> subtitles;
  final ExtSubtitle? selectedSubtitle;
  final ValueChanged<ExtSubtitle?> onSubtitleSelected;

  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const VideoPlayerSettingsModal({
    super.key,
    required this.videos,
    required this.selectedVideo,
    required this.onQualitySelected,
    required this.subtitles,
    required this.selectedSubtitle,
    required this.onSubtitleSelected,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  State<VideoPlayerSettingsModal> createState() =>
      _VideoPlayerSettingsModalState();
}

class _VideoPlayerSettingsModalState extends State<VideoPlayerSettingsModal> {
  _SettingsSubMenu _activeSubMenu = _SettingsSubMenu.main;

  static const List<double> _availableSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  void _navigateToSubMenu(_SettingsSubMenu subMenu) {
    setState(() {
      _activeSubMenu = subMenu;
    });
  }

  void _navigateBackToMain() {
    setState(() {
      _activeSubMenu = _SettingsSubMenu.main;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final String qualityText = widget.selectedVideo?.quality ?? 'Default';
    final String subtitleText = widget.selectedSubtitle?.label ?? 'Off';
    final String speedText = '${widget.currentSpeed}x';

    return SafeArea(
      child: ClipRect(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 295),
          child: Padding(
            padding: const EdgeInsets.only(top: 26, bottom: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isSubMenu = child.key == const ValueKey('sub_menu');
                final inOffset = isSubMenu
                    ? const Offset(1.0, 0.0)
                    : const Offset(-1.0, 0.0);

                return SlideTransition(
                  position: Tween<Offset>(
                    begin: inOffset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: Align(alignment: Alignment.topCenter, child: child),
                );
              },
              child: _activeSubMenu == _SettingsSubMenu.main
                  ? _buildMainMenu(
                      context,
                      theme,
                      qualityText,
                      subtitleText,
                      speedText,
                    )
                  : _buildSubMenu(context, primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(
    BuildContext context,
    ThemeData theme,
    String qualityText,
    String subtitleText,
    String speedText,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('main_menu'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Playback Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Quality'),
            subtitle: Text(
              qualityText,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToSubMenu(_SettingsSubMenu.quality),
          ),
          ListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitles'),
            subtitle: Text(
              subtitleText,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToSubMenu(_SettingsSubMenu.subtitles),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Playback Speed'),
            subtitle: Text(
              speedText,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToSubMenu(_SettingsSubMenu.speed),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMenu(BuildContext context, Color primaryColor) {
    return Column(
      key: const ValueKey('sub_menu'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBackToMain,
              ),
              Text(
                _getSubMenuTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildSubMenuOptions(primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  String _getSubMenuTitle() {
    switch (_activeSubMenu) {
      case _SettingsSubMenu.quality:
        return 'Select Quality';
      case _SettingsSubMenu.subtitles:
        return 'Select Subtitles';
      case _SettingsSubMenu.speed:
        return 'Playback Speed';
      case _SettingsSubMenu.main:
        return 'Settings';
    }
  }

  List<Widget> _buildSubMenuOptions(Color primaryColor) {
    switch (_activeSubMenu) {
      case _SettingsSubMenu.quality:
        return widget.videos.map((video) {
          final isSel = video == widget.selectedVideo;
          return ListTile(
            title: Text(
              video.quality,
              style: TextStyle(
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? primaryColor : null,
              ),
            ),
            trailing: isSel ? Icon(Icons.check, color: primaryColor) : null,
            onTap: () {
              Navigator.of(context).pop();
              if (!isSel) widget.onQualitySelected(video);
            },
          );
        }).toList();

      case _SettingsSubMenu.subtitles:
        return [
          ListTile(
            title: Text(
              'Off',
              style: TextStyle(
                fontWeight: widget.selectedSubtitle == null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: widget.selectedSubtitle == null ? primaryColor : null,
              ),
            ),
            trailing: widget.selectedSubtitle == null
                ? Icon(Icons.check, color: primaryColor)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              widget.onSubtitleSelected(null);
            },
          ),
          ...widget.subtitles.map((sub) {
            final isSel = widget.selectedSubtitle?.file == sub.file;
            return ListTile(
              title: Text(
                sub.label,
                style: TextStyle(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? primaryColor : null,
                ),
              ),
              trailing: isSel ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () {
                Navigator.of(context).pop();
                if (!isSel) widget.onSubtitleSelected(sub);
              },
            );
          }),
        ];

      case _SettingsSubMenu.speed:
        return _availableSpeeds.map((speed) {
          final isSel = speed == widget.currentSpeed;
          return ListTile(
            title: Text(
              '${speed}x',
              style: TextStyle(
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? primaryColor : null,
              ),
            ),
            trailing: isSel ? Icon(Icons.check, color: primaryColor) : null,
            onTap: () {
              Navigator.of(context).pop();
              if (!isSel) widget.onSpeedSelected(speed);
            },
          );
        }).toList();

      case _SettingsSubMenu.main:
        return [];
    }
  }
}
