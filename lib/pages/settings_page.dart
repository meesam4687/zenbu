import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:zenbu/pages/anilist_settings_page.dart';
import 'package:zenbu/pages/appearance_settings_page.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/discord_service.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCheckingUpdate = false;
  UpdateInfo? _updateInfo;
  bool _hasUpdate = false;

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
        Fluttertoast.showToast(msg: context.l10n.appIsUpToDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader(label: context.l10n.aniList),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: SvgPicture.asset(
                        'assets/alLogo.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          cs.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Text(
                        context.l10n.aniListSettings,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        context.l10n.aniListSettingsSubtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AnilistSettingsPage(),
                          ),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                _SectionHeader(label: context.l10n.mangayomi),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.extension_rounded, color: cs.primary),
                      title: Text(
                        context.l10n.extensions,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        context.l10n.extensionsSubtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ExtensionsPage(),
                          ),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                _SectionHeader(label: context.l10n.appearance),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.palette_rounded, color: cs.primary),
                      title: Text(
                        context.l10n.themeAndColors,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _themeModeLabel(provider.themeMode, context),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AppearanceSettingsPage(),
                          ),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                _SectionHeader(label: context.l10n.integrations),
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
                            title: Text(context.l10n.discord),
                            subtitle: Text(context.l10n.notLinkedTapToConnect),
                            trailing: TextButton(
                              onPressed: () async {
                                await DiscordService.startAuthorizationFlow();
                              },
                              child: Text(
                                context.l10n.link,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () async {
                              await DiscordService.startAuthorizationFlow();
                            },
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
                                  title: Text(context.l10n.discord),
                                  subtitle: Text(
                                    isEnabled
                                        ? context.l10n.linkedPresenceActive
                                        : context.l10n.linkedPresencePaused,
                                  ),
                                  trailing: Switch(
                                    value: isEnabled,
                                    onChanged: (val) async {
                                      await DiscordService.setPresenceEnabled(
                                        val,
                                      );
                                    },
                                  ),
                                  onTap: () async {
                                    await DiscordService.setPresenceEnabled(
                                      !isEnabled,
                                    );
                                  },
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.link_off_rounded,
                                    color: cs.error,
                                  ),
                                  title: Text(
                                    context.l10n.unlinkAccount,
                                    style: TextStyle(
                                      color: cs.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () async {
                                    final l10n = context.l10n;
                                    await DiscordService.unlink();
                                    Fluttertoast.showToast(
                                      msg: l10n.discordAccountUnlinked,
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

                _SectionHeader(label: context.l10n.about),
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
                            title: Text(context.l10n.checkForUpdates),
                            subtitle: Text(context.l10n.checkForNewerVersion),
                            trailing: _isCheckingUpdate
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                              context.l10n.updateAvailableWithVersion(
                                _updateInfo?.remoteVersion ?? '',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            subtitle: Text(context.l10n.tapToViewAndInstall),
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
                              child: Text(context.l10n.view),
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
          ),
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.light:
        return context.l10n.light;
      case ThemeMode.dark:
        return context.l10n.dark;
      case ThemeMode.system:
        return context.l10n.systemDefault;
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
      if (mounted) {
        Fluttertoast.showToast(msg: context.l10n.couldNotOpenGitHub);
      }
    }
  }

  Future<void> _openDiscord() async {
    final uri = Uri.parse('https://discord.gg/tJRA5NPQXY');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        Fluttertoast.showToast(msg: context.l10n.couldNotOpenDiscord);
      }
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                iconPath: 'assets/github.svg',
                onTap: _openGitHub,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              _SocialButton(
                iconPath: 'assets/discord.svg',
                onTap: _openDiscord,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;
  final Color color;

  const _SocialButton({
    required this.iconPath,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SvgPicture.asset(
          iconPath,
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
