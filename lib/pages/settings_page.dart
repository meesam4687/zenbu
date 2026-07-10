import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/services/anilist/update_user.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/discord_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCheckingUpdate = false;
  UpdateInfo? _updateInfo;
  bool _hasUpdate = false;

  bool _isSavingLang = false;

  @override
  void initState() {
    super.initState();
    _loadCachedUpdate();
    DiscordService.isLinked();
  }

  Future<void> _loadCachedUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('cached_update_version');
    final c = prefs.getString('cached_update_changelog');
    final u = prefs.getString('cached_update_url');
    if (v != null && c != null && u != null && mounted) {
      setState(() {
        _hasUpdate = true;
        _updateInfo = UpdateInfo(
          remoteVersion: v,
          changelog: c,
          downloadUrl: u,
        );
      });
    }
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    final info = await UpdateService.checkUpdate(force: true);
    final prefs = await SharedPreferences.getInstance();
    if (info != null) {
      await prefs.setString('cached_update_version', info.remoteVersion);
      await prefs.setString('cached_update_changelog', info.changelog);
      await prefs.setString('cached_update_url', info.downloadUrl);
      if (mounted) {
        setState(() {
          _hasUpdate = true;
          _updateInfo = info;
          _isCheckingUpdate = false;
        });
      }
    } else {
      await UpdateService.clearUpdateCache();
      if (mounted) {
        setState(() {
          _hasUpdate = false;
          _updateInfo = null;
          _isCheckingUpdate = false;
        });
        Fluttertoast.showToast(msg: 'App is up to date!');
      }
    }
  }

  Future<void> _setTitleLanguage(String lang, StateProvider provider) async {
    if (_isSavingLang) return;
    setState(() => _isSavingLang = true);
    try {
      await updateUserTitleLanguage(lang);
      provider.titleLanguage = lang;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update title language: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isSavingLang = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(label: 'Display'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Title Language',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isSavingLang) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How titles are shown throughout the app. Synced with your AniList account.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ROMAJI', label: Text('Romaji')),
                        ButtonSegment(value: 'ENGLISH', label: Text('English')),
                        ButtonSegment(value: 'NATIVE', label: Text('Native')),
                      ],
                      selected: {provider.titleLanguage},
                      onSelectionChanged: _isSavingLang
                          ? null
                          : (Set<String> selection) {
                              _setTitleLanguage(selection.first, provider);
                            },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: cs.primaryContainer,
                        selectedForegroundColor: cs.onPrimaryContainer,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _SectionHeader(label: 'Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Icon(Icons.palette_rounded, color: cs.primary),
                  title: Text(
                    'Theme',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _themeModeLabel(provider.themeMode),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                      ],
                      selected: {provider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        provider.themeMode = selection.first;
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: cs.primaryContainer,
                        selectedForegroundColor: cs.onPrimaryContainer,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Accent Colour',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ColorSwatchRow(
                      selected: provider.seedColor,
                      onSelected: (color) => provider.seedColor = color,
                    ),
                  ],
                ),
              ),
            ),
          ),

          _SectionHeader(label: 'Integrations'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: DiscordService.discordLinked,
                builder: (context, isLinked, _) {
                  if (!isLinked) {
                    return ListTile(
                      leading: SvgPicture.asset(
                        'assets/discord.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          cs.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: const Text('Discord'),
                      subtitle: const Text('Not linked  •  Tap to connect'),
                      trailing: TextButton(
                        onPressed: () async {
                          await DiscordService.startAuthorizationFlow();
                        },
                        child: Text(
                          'Link',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  }

                  return ValueListenableBuilder<bool>(
                    valueListenable: DiscordService.presenceEnabled,
                    builder: (context, isEnabled, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/discord.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                cs.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            title: const Text('Discord'),
                            subtitle: Text(
                              isEnabled
                                  ? 'Linked  •  Presence active'
                                  : 'Linked  •  Presence paused',
                            ),
                            trailing: Switch(
                              value: isEnabled,
                              onChanged: (val) async {
                                await DiscordService.setPresenceEnabled(val);
                              },
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: Icon(
                              Icons.link_off_rounded,
                              color: cs.error,
                            ),
                            title: Text(
                              'Unlink Account',
                              style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () async {
                              await DiscordService.unlink();
                              Fluttertoast.showToast(
                                msg: 'Discord account unlinked',
                              );
                            },
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          _SectionHeader(label: 'About'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (!_hasUpdate)
                    ListTile(
                      leading: Icon(
                        Icons.system_update_rounded,
                        color: cs.primary,
                      ),
                      title: const Text('Check for Updates'),
                      subtitle: const Text(
                        'Check for a newer version of Zenbu',
                      ),
                      trailing: _isCheckingUpdate
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _isCheckingUpdate ? null : _checkUpdate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    )
                  else
                    ListTile(
                      leading: Icon(
                        Icons.system_update_alt_rounded,
                        color: cs.primary,
                      ),
                      title: Text(
                        'Update Available  •  ${_updateInfo?.remoteVersion}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      subtitle: const Text('Tap to view and install'),
                      trailing: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UpdatePage(updateInfo: _updateInfo!),
                            ),
                          );
                        },
                        child: const Text('View'),
                      ),
                      onTap: _isCheckingUpdate ? null : _checkUpdate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const _AppFooter(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color?> onSelected;

  const _ColorSwatchRow({required this.selected, required this.onSelected});

  static const _swatches = [
    _Swatch(label: 'System', color: null),
    _Swatch(label: 'Purple', color: Color(0xFF6750A4)),
    _Swatch(label: 'Blue', color: Color(0xFF1565C0)),
    _Swatch(label: 'Teal', color: Color(0xFF00695C)),
    _Swatch(label: 'Green', color: Color(0xFF2E7D32)),
    _Swatch(label: 'Amber', color: Color(0xFFE65100)),
    _Swatch(label: 'Red', color: Color(0xFFC62828)),
    _Swatch(label: 'Pink', color: Color(0xFFAD1457)),
    _Swatch(label: 'Indigo', color: Color(0xFF283593)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _swatches.map((s) {
        final isSelected = s.color == selected;
        return _ColorSwatch(
          swatch: s,
          isSelected: isSelected,
          onTap: () => onSelected(s.color),
        );
      }).toList(),
    );
  }
}

class _Swatch {
  final String label;
  final Color? color;
  const _Swatch({required this.label, required this.color});
}

class _ColorSwatch extends StatelessWidget {
  final _Swatch swatch;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.swatch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayColor = swatch.color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: swatch.color == null
                  ? cs.surfaceContainerHighest
                  : displayColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? cs.onSurface : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: displayColor.withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: swatch.color == null
                ? Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  )
                : isSelected
                ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            swatch.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppFooter extends StatefulWidget {
  const _AppFooter();

  @override
  State<_AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<_AppFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version}');
    }
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/meesam4687/zenbu');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(msg: 'Could not open GitHub');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Divider(color: cs.outlineVariant.withAlpha(80)),
          const SizedBox(height: 28),

          SvgPicture.asset(
            'assets/zenbu.svg',
            width: 80,
            height: 80,
            colorFilter: ColorFilter.mode(
              cs.onSurface.withAlpha(220),
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _version.isEmpty ? '' : _version,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 16),

          _GitHubButton(onTap: _openGitHub, color: cs.onSurfaceVariant),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GitHubButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _GitHubButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SvgPicture.asset(
          'assets/github.svg',
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
