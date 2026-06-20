import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/components/global/spoiler.dart';

class CharacterDescription extends StatelessWidget {
  const CharacterDescription({
    super.key,
    required this.characterGender,
    required this.characterDescription,
  });

  final String characterGender;
  final String characterDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Gender: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(characterGender, style: const TextStyle(fontSize: 17)),
            ],
          ),
          const SizedBox(height: 5),
          MarkdownBody(
            data: preprocessSpoilers(characterDescription),
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(p: const TextStyle(fontSize: 16)),
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.parse(href);
                try {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                } catch (_) {}
              }
            },
            inlineSyntaxes: [SpoilerSyntax()],
            builders: {'spoiler': SpoilerBuilder()},
          ),
        ],
      ),
    );
  }
}
