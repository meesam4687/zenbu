import 'package:flutter/material.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/components/video_player_page/custom_subtitle_view.dart';

class SubtitleCustomizationSheet extends StatefulWidget {
  final SubtitleConfig initialConfig;
  final ValueChanged<SubtitleConfig> onConfigChanged;
  final String? previewImageUrl;

  const SubtitleCustomizationSheet({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    this.previewImageUrl,
  });

  @override
  State<SubtitleCustomizationSheet> createState() =>
      _SubtitleCustomizationSheetState();
}

class _SubtitleCustomizationSheetState
    extends State<SubtitleCustomizationSheet> {
  late SubtitleConfig _config;

  static const List<Map<String, dynamic>> _textColorOptions = [
    {'name': 'White', 'color': Color(0xFFFFFFFF), 'value': 0xFFFFFFFF},
    {'name': 'Yellow', 'color': Color(0xFFFFF176), 'value': 0xFFFFF176},
    {'name': 'Cyan', 'color': Color(0xFF80DEEA), 'value': 0xFF80DEEA},
    {'name': 'Green', 'color': Color(0xFFA5D6A7), 'value': 0xFFA5D6A7},
    {'name': 'Coral', 'color': Color(0xFFFF8A80), 'value': 0xFFFF8A80},
  ];

  static const List<String> _fontFamilyOptions = [
    'Liberation Sans',
    'Roboto',
    'Trebuchet MS',
    'Monospace',
    'Serif',
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(SubtitleConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isCustom = _config.preset == SubtitlePreset.custom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customize Subtitles',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewCard(theme),

                  const SizedBox(height: 18),

                  const Text(
                    'Preset Style',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _buildPresetCards(primaryColor, theme),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customization Options',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isCustom)
                        Text(
                          'Select Custom above to edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCustom ? 1.0 : 0.38,
                    child: IgnorePointer(
                      ignoring: !isCustom,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFontSizeSection(theme),
                          const Divider(height: 24),

                          _buildFontFamilySection(theme),
                          const Divider(height: 24),

                          _buildFontWeightSection(theme),
                          const Divider(height: 24),

                          _buildTextColorSection(theme),
                          const Divider(height: 24),

                          _buildBorderWidthSection(theme),
                          const Divider(height: 24),

                          _buildBackgroundSection(theme),
                          const Divider(height: 24),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Drop Shadow'),
                            subtitle: const Text(
                              'Adds depth and high contrast against bright scenes',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _config.hasShadow,
                            onChanged: (val) {
                              _updateConfig(_config.copyWith(hasShadow: val));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 145,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.previewImageUrl != null &&
                widget.previewImageUrl!.isNotEmpty)
              CustomImage(imageUrl: widget.previewImageUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3C72),
                      Color(0xFF2A5298),
                      Color(0xFFE2B0FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            Positioned(
              top: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: CustomSubtitleView(
                text: 'Subtitles will look like this\nAnime subtitle preview',
                config: _config,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCards(Color primaryColor, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildPresetCard(
            title: 'Default',
            icon: Icons.auto_awesome,
            preset: SubtitlePreset.defaultOutline,
            primaryColor: primaryColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPresetCard(
            title: 'Normal',
            icon: Icons.border_style,
            preset: SubtitlePreset.classicBorder,
            primaryColor: primaryColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPresetCard(
            title: 'Custom',
            icon: Icons.tune,
            preset: SubtitlePreset.custom,
            primaryColor: primaryColor,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard({
    required String title,
    required IconData icon,
    required SubtitlePreset preset,
    required Color primaryColor,
    required ThemeData theme,
  }) {
    final isSelected = _config.preset == preset;

    return InkWell(
      onTap: () {
        _updateConfig(_config.copyWith(preset: preset));
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? primaryColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Font Size',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_config.fontSize.round()} pt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: _config.fontSize > 14
                  ? () => _updateConfig(
                      _config.copyWith(fontSize: _config.fontSize - 1),
                    )
                  : null,
            ),
            Expanded(
              child: Slider(
                value: _config.fontSize.clamp(14.0, 32.0),
                min: 14.0,
                max: 32.0,
                divisions: 18,
                onChanged: (val) {
                  _updateConfig(_config.copyWith(fontSize: val));
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: _config.fontSize < 32
                  ? () => _updateConfig(
                      _config.copyWith(fontSize: _config.fontSize + 1),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontFamilySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Family',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _fontFamilyOptions.map((font) {
            final isSelected = _config.fontFamily == font;
            return ChoiceChip(
              label: Text(font),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateConfig(_config.copyWith(fontFamily: font));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontWeightSection(ThemeData theme) {
    const weightLabels = ['Normal', 'Semi-Bold', 'Bold'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Weight',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(weightLabels.length, (idx) {
            final isSelected = _config.fontWeightIndex == idx;
            return ChoiceChip(
              label: Text(weightLabels[idx]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateConfig(_config.copyWith(fontWeightIndex: idx));
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextColorSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Color',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _textColorOptions.map((opt) {
            final colorVal = opt['value'] as int;
            final isSelected = _config.textColorValue == colorVal;
            final color = opt['color'] as Color;

            return InkWell(
              onTap: () {
                _updateConfig(_config.copyWith(textColorValue: colorVal));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBorderWidthSection(ThemeData theme) {
    const borders = [
      {'name': 'None', 'value': 0.0},
      {'name': 'Thin (1.5px)', 'value': 1.5},
      {'name': 'Medium (2.8px)', 'value': 2.8},
      {'name': 'Thick (4.0px)', 'value': 4.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Border Outline',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: borders.map((opt) {
            final val = opt['value'] as double;
            final isSelected = (_config.borderWidth - val).abs() < 0.1;

            return ChoiceChip(
              label: Text(opt['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateConfig(_config.copyWith(borderWidth: val));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundSection(ThemeData theme) {
    const backgrounds = [
      {'name': 'None', 'value': 0.0},
      {'name': 'Subtle (30%)', 'value': 0.30},
      {'name': 'Medium (60%)', 'value': 0.60},
      {'name': 'Solid (100%)', 'value': 1.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Box',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: backgrounds.map((opt) {
            final val = opt['value'] as double;
            final isSelected = (_config.backgroundOpacity - val).abs() < 0.05;

            return ChoiceChip(
              label: Text(opt['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateConfig(_config.copyWith(backgroundOpacity: val));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
