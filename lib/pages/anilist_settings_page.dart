import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/services/anilist/update_user.dart';

class AnilistSettingsPage extends StatefulWidget {
  const AnilistSettingsPage({super.key});

  @override
  State<AnilistSettingsPage> createState() => _AnilistSettingsPageState();
}

class _AnilistSettingsPageState extends State<AnilistSettingsPage> {
  bool _isSavingLang = false;
  bool _isSavingNsfw = false;

  Future<void> _setTitleLanguage(String lang, StateProvider provider) async {
    if (_isSavingLang) return;
    setState(() => _isSavingLang = true);
    try {
      await updateUserTitleLanguage(lang);
      provider.titleLanguage = lang;
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to update title language: $e',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingLang = false);
    }
  }

  Future<void> _setDisplayAdultContent(bool val, StateProvider provider) async {
    if (_isSavingNsfw) return;
    setState(() => _isSavingNsfw = true);
    try {
      await updateUserDisplayAdultContent(val);
      provider.displayAdultContent = val;
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to update NSFW preference: $e',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNsfw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AniList Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(label: 'Metadata'),
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
          _SectionHeader(label: 'Content Preferences'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Icon(Icons.explicit_rounded, color: cs.primary),
                title: Text(
                  'Show NSFW Content',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Display adult (18+) anime and manga. Synced with your AniList account.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: _isSavingNsfw
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: provider.displayAdultContent,
                        onChanged: (val) {
                          _setDisplayAdultContent(val, provider);
                        },
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
