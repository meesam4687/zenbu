import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

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
        child: SizedBox(
          width: 150,
          height: 200,
          child: Column(
            children: [
              Text(
                "Zenbu",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w100),
              ),
              Text(
                "*insert some line here*",
                style: TextStyle(fontWeight: FontWeight.w200),
              ),
              Padding(padding: EdgeInsetsGeometry.all(10)),
              FilledButton(
                onPressed: () {
                  final uri = Uri.tryParse(
                    'https://anilist.co/api/v2/oauth/authorize?client_id=29014&response_type=token',
                  );
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(20)),
                  minimumSize: WidgetStatePropertyAll(Size.fromHeight(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Login with", style: TextStyle(fontSize: 16)),
                    Padding(padding: EdgeInsetsGeometry.all(2)),
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
            ],
          ),
        ),
      ),
    );
  }
}
