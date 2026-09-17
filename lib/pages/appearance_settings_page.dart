import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/pages/language_settings_page.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appearance)),
      body: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader(label: context.l10n.appLanguage),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(
                        context.l10n.appLanguage,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        LanguageSettingsPage.getLanguageName(
                          context,
                          provider.locale,
                        ),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LanguageSettingsPage(),
                          ),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                _SectionHeader(label: context.l10n.themeMode),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.themeModeSubtitle,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(context.l10n.system),
                                icon: const Icon(Icons.brightness_auto_rounded),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(context.l10n.light),
                                icon: const Icon(Icons.light_mode_rounded),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(context.l10n.dark),
                                icon: const Icon(Icons.dark_mode_rounded),
                              ),
                            ],
                            selected: {provider.themeMode},
                            onSelectionChanged: (Set<ThemeMode> selection) {
                              final newMode = selection.first;
                              provider.themeMode = newMode;

                              if (provider.selectedCustomTheme == 'Midnight') {
                                final systemBrightness =
                                    MediaQuery.platformBrightnessOf(context);
                                if (newMode == ThemeMode.light ||
                                    (newMode == ThemeMode.system &&
                                        systemBrightness == Brightness.light)) {
                                  provider.selectedCustomTheme = null;
                                }
                              }
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
                _SectionHeader(label: context.l10n.accentColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.personaliseColorScheme,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ColorSwatchRow(
                            selectedCustomTheme: provider.selectedCustomTheme,
                            selectedSeedColor: provider.seedColor,
                            onSelected: (color, customThemeName) {
                              if (customThemeName != null) {
                                if (customThemeName == 'Midnight') {
                                  final systemBrightness =
                                      MediaQuery.platformBrightnessOf(context);
                                  if (provider.themeMode == ThemeMode.light ||
                                      (provider.themeMode == ThemeMode.system &&
                                          systemBrightness ==
                                              Brightness.light)) {
                                    provider.themeMode = ThemeMode.dark;
                                  }
                                }
                                provider.selectedCustomTheme = customThemeName;
                                provider.seedColor = null;
                              } else {
                                provider.selectedCustomTheme = null;
                                provider.seedColor = color;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _SectionHeader(label: context.l10n.homeScreenLayout),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: provider.homeListOrder.length,
                        onReorderItem: (oldIndex, newIndex) {
                          final items = List<String>.from(
                            provider.homeListOrder,
                          );
                          final item = items.removeAt(oldIndex);
                          items.insert(newIndex, item);
                          provider.homeListOrder = items;
                        },
                        itemBuilder: (context, index) {
                          final key = provider.homeListOrder[index];

                          Widget tile;
                          if (key == 'anime') {
                            tile = ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: cs.outline,
                                ),
                              ),
                              title: Text(context.l10n.showAnimeList),
                              subtitle: Text(
                                context.l10n.displayCurrentlyWatchingAnime,
                              ),
                              trailing: Switch.adaptive(
                                value: provider.showAnimeList,
                                onChanged: (bool value) {
                                  provider.showAnimeList = value;
                                },
                              ),
                            );
                          } else if (key == 'manga') {
                            tile = ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: cs.outline,
                                ),
                              ),
                              title: Text(context.l10n.showMangaList),
                              subtitle: Text(
                                context.l10n.displayCurrentlyReadingManga,
                              ),
                              trailing: Switch.adaptive(
                                value: provider.showMangaList,
                                onChanged: (bool value) {
                                  provider.showMangaList = value;
                                },
                              ),
                            );
                          } else {
                            tile = ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: cs.outline,
                                ),
                              ),
                              title: Text(context.l10n.showRecommendations),
                              subtitle: Text(
                                context.l10n.displayRecommendationsBasedOnAnime,
                              ),
                              trailing: Switch.adaptive(
                                value: provider.showRecommendationsList,
                                onChanged: (bool value) {
                                  provider.showRecommendationsList = value;
                                },
                              ),
                            );
                          }

                          return Column(
                            key: ValueKey(key),
                            children: [
                              tile,
                              if (index < provider.homeListOrder.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 56,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  final String? selectedCustomTheme;
  final Color? selectedSeedColor;
  final void Function(Color? color, String? customThemeName) onSelected;

  const _ColorSwatchRow({
    required this.selectedCustomTheme,
    required this.selectedSeedColor,
    required this.onSelected,
  });

  static final _swatches = [
    _Swatch(getLabel: (c) => c.l10n.system, color: null),
    _Swatch(
      getLabel: (c) => c.l10n.themeMidnight,
      color: Colors.black,
      customThemeName: 'Midnight',
    ),
    _Swatch(
      getLabel: (c) => c.l10n.colorPurple,
      color: const Color(0xFF6750A4),
    ),
    _Swatch(getLabel: (c) => c.l10n.colorBlue, color: const Color(0xFF1565C0)),
    _Swatch(getLabel: (c) => c.l10n.colorTeal, color: const Color(0xFF00695C)),
    _Swatch(getLabel: (c) => c.l10n.colorGreen, color: const Color(0xFF2E7D32)),
    _Swatch(getLabel: (c) => c.l10n.colorAmber, color: const Color(0xFFE65100)),
    _Swatch(getLabel: (c) => c.l10n.colorRed, color: const Color(0xFFC62828)),
    _Swatch(getLabel: (c) => c.l10n.colorPink, color: const Color(0xFFAD1457)),
    _Swatch(
      getLabel: (c) => c.l10n.colorIndigo,
      color: const Color(0xFF283593),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _swatches.map((s) {
        final isSelected = s.customThemeName != null
            ? selectedCustomTheme == s.customThemeName
            : (selectedCustomTheme == null && s.color == selectedSeedColor);

        return _ColorSwatch(
          swatch: s,
          isSelected: isSelected,
          onTap: () => onSelected(s.color, s.customThemeName),
        );
      }).toList(),
    );
  }
}

class _Swatch {
  final String Function(BuildContext) getLabel;
  final Color? color;
  final String? customThemeName;
  const _Swatch({required this.getLabel, this.color, this.customThemeName});
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
            swatch.getLabel(context),
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
