import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(label: 'Theme Mode'),
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
                      'Choose how Zenbu looks on your device.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
            ),
          ),
          _SectionHeader(label: 'Accent Colour'),
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
                      'Personalise the primary colour scheme.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _ColorSwatchRow(
                      selected: provider.seedColor,
                      onSelected: (color) => provider.seedColor = color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
