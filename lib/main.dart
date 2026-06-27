import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/main_page_view.dart';
import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:zenbu/deep_link_controller.dart';

String? token;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  token = await TokenStorage.getAccessToken();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkController _deepLinkController;

  @override
  void initState() {
    super.initState();
    _deepLinkController = DeepLinkController(navigatorKey: _navigatorKey);
    _deepLinkController.init();
  }

  @override
  void dispose() {
    _deepLinkController.dispose();
    super.dispose();
  }

  static final defaultColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return StateProvider();
      },
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          ColorScheme lightScheme = lightDynamic ?? defaultColorScheme;
          ColorScheme darkScheme =
              darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              );

          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Zenbu',
            theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
            darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
            themeMode: ThemeMode.system,
            home: (token == null) ? AuthenticationPage() : MainPageView(),
          );
        },
      ),
    );
  }
}
