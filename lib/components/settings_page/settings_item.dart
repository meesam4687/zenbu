import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    required this.icon,
    this.titleText,
    this.titleWidget,
    this.subtitleText,
    this.subtitleWidget,
    this.targetPage,
    this.trailing,
    this.onTap,
    this.child,
  });

  final Widget icon;
  final String? titleText;
  final Widget? titleWidget;
  final String? subtitleText;
  final Widget? subtitleWidget;
  final Widget? targetPage;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Card(
        elevation: 0,
        color: cs.onInverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child:
            child ??
            ListTile(
              leading: icon,
              title:
                  titleWidget ??
                  (titleText != null
                      ? Text(
                          titleText!,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null),
              subtitle:
                  subtitleWidget ??
                  (subtitleText != null
                      ? Text(
                          subtitleText!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : null),
              trailing:
                  trailing ??
                  (targetPage != null || onTap != null
                      ? const Icon(Icons.chevron_right_rounded)
                      : null),
              onTap:
                  onTap ??
                  (targetPage != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => targetPage!,
                            ),
                          );
                        }
                      : null),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
      ),
    );
  }
}
