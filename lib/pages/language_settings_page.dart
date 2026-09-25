import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/state_provider.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  static List<({String name, Locale? locale})> getLanguages(
    BuildContext context,
  ) => [
    (name: context.l10n.systemDefault, locale: null),
    (name: context.l10n.englishGB, locale: const Locale('en', 'GB')),
    (name: context.l10n.englishUS, locale: const Locale('en', 'US')),
  ];

  static String getLanguageName(BuildContext context, Locale? locale) {
    for (final lang in getLanguages(context)) {
      if (lang.locale == locale) {
        return lang.name;
      }
    }
    return context.l10n.systemDefault;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final currentLocale = provider.locale;
    final languages = getLanguages(context);

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
                                fontWeight: currentLocale == languages[i].locale
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: currentLocale == languages[i].locale
                                    ? cs.primary
                                    : cs.onSurface,
                              ),
                            ),
                            trailing: currentLocale == languages[i].locale
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
