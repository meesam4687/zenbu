import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/state_provider.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final currentLocale = provider.locale;
    final selectedCode = currentLocale == null
        ? 'system'
        : currentLocale.countryCode == 'GB'
        ? 'en_GB'
        : currentLocale.countryCode == 'US'
        ? 'en_US'
        : 'system';

    final languages = [
      (code: 'system', name: context.l10n.systemDefault, locale: null),
      (
        code: 'en_GB',
        name: context.l10n.englishGB,
        locale: const Locale('en', 'GB'),
      ),
      (
        code: 'en_US',
        name: context.l10n.englishUS,
        locale: const Locale('en', 'US'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appLanguage)),
      body: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < languages.length; i++) ...[
                          ListTile(
                            title: Text(
                              languages[i].name,
                              style: TextStyle(
                                fontWeight: selectedCode == languages[i].code
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selectedCode == languages[i].code
                                    ? cs.primary
                                    : cs.onSurface,
                              ),
                            ),
                            trailing: selectedCode == languages[i].code
                                ? Icon(Icons.check_rounded, color: cs.primary)
                                : null,
                            onTap: () {
                              provider.locale = languages[i].locale;
                            },
                          ),
                          if (i < languages.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: cs.outlineVariant.withAlpha(50),
                            ),
                        ],
                      ],
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
