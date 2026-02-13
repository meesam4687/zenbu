import 'package:zenbu/main_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/authentication_token_controller.dart';

final AppLinks _appLinks = AppLinks();
late String authToken;

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
  void _listenToLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      authToken = uri.fragment.split("=")[1].split("&")[0];
      await TokenStorage.saveTokens(accessToken: authToken);
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const MainPageView()),
      );
    });
  }

  @override
  void initState() {
    _listenToLinks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: SizedBox(
          width: 150,
          height: 200,
          child: Column(
            children: [
              const Text(
                "Zenbu",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w100),
              ),
              const Text(
                "*insert some line here*",
                style: TextStyle(fontWeight: FontWeight.w200),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              CupertinoButton.filled(
                onPressed: () {
                  final uri = Uri.tryParse(
                    'https://anilist.co/api/v2/oauth/authorize?client_id=29014&response_type=token',
                  );
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Login with", style: TextStyle(fontSize: 16)),
                    const Padding(padding: EdgeInsets.all(2)),
                    SvgPicture.asset(
                      'assets/alLogo.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        CupertinoColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
