import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/main_page_view.dart';
import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/authentication_token_controller.dart';

String? token;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  token = await TokenStorage.getAccessToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const defaultPrimaryColor = CupertinoColors.systemPurple;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return StateProvider();
      },
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // Extract primary color from dynamic color if available
          final primaryColor = lightDynamic?.primary != null 
              ? Color(lightDynamic!.primary.value) 
              : defaultPrimaryColor;

          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            title: 'Zenbu',
            theme: CupertinoThemeData(
              primaryColor: primaryColor,
              brightness: Brightness.light,
            ),
            home: (token == null) ? const AuthenticationPage() : const MainPageView(),
          );
        },
      ),
    );
  }
}
