import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

Future<void> openInBrowser(String url) async {
  final uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    throw 'Could not launch $url';
  }
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.appTitle,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.insertSomeLineHere,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w200),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final uri = Uri.tryParse(
                    'https://anilist.co/api/v2/oauth/authorize?client_id=29014&response_type=token',
                  );
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(20)),
                  minimumSize: WidgetStatePropertyAll(Size(150, 10)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.loginWith,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/alLogo.svg',
                        width: 18,
                        height: 18,
                        // ignore: deprecated_member_use
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
