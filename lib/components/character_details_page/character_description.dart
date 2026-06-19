import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class SpoilerSyntax extends md.InlineSyntax {
  SpoilerSyntax() : super(r'~\!([\s\S]*?)\!~');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final textContent = match.group(1)!;

    final element = md.Element('spoiler', [md.Text(textContent)]);
    element.attributes['content'] = textContent;
    parser.addNode(element);
    return true;
  }
}

class SpoilerBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawContent = element.attributes['content'] ?? '';
    return SpoilerWidget(markdown: rawContent, style: preferredStyle);
  }
}

class SpoilerWidget extends StatefulWidget {
  final String markdown;
  final TextStyle? style;

  const SpoilerWidget({super.key, required this.markdown, this.style});

  @override
  State<SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        setState(() {
          _revealed = !_revealed;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _revealed ? Colors.transparent : bannerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: _revealed ? 1.0 : 0.0,
          child: AbsorbPointer(
            absorbing: !_revealed,
            child: IntrinsicWidth(
              child: MarkdownBody(
                data: widget.markdown,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
            data: characterDescription,
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
