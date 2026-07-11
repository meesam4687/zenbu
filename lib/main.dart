import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/theme/custom_themes.dart';
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

  static final _defaultLightScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
  );
  static final _defaultDarkScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StateProvider(),
      child: Consumer<StateProvider>(
        builder: (context, provider, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              final seedColor = provider.seedColor;

              ColorScheme lightScheme = seedColor != null
                  ? ColorScheme.fromSeed(seedColor: seedColor)
                  : lightDynamic ?? _defaultLightScheme;
              ColorScheme darkScheme = seedColor != null
                  ? ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.dark,
                    )
                  : darkDynamic ?? _defaultDarkScheme;

              final customTheme = provider.selectedCustomTheme != null
                  ? customThemes.firstWhere(
                      (t) => t.name == provider.selectedCustomTheme,
                      orElse: () => customThemes[0],
                    )
                  : null;

              if (customTheme != null) {
                if (customTheme.isLightOnly) {
                  lightScheme = customTheme.colorScheme;
                } else if (customTheme.isDarkOnly) {
                  darkScheme = customTheme.colorScheme;
                } else {
                  if (customTheme.colorScheme.brightness == Brightness.dark) {
                    darkScheme = customTheme.colorScheme;
                  } else {
                    lightScheme = customTheme.colorScheme;
                  }
                }
              }

              return MaterialApp(
                navigatorKey: _navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'Zenbu',
                theme: ThemeData(
                  colorScheme: lightScheme,
                  scaffoldBackgroundColor:
                      (customTheme != null && customTheme.isLightOnly)
                      ? customTheme.scaffoldBackgroundColor
                      : null,
                  useMaterial3: true,
                ),
                darkTheme: ThemeData(
                  colorScheme: darkScheme,
                  scaffoldBackgroundColor:
                      (customTheme != null && customTheme.isDarkOnly)
                      ? customTheme.scaffoldBackgroundColor
                      : null,
                  useMaterial3: true,
                ),
                themeMode: provider.themeMode,
                home: (token == null) ? AuthenticationPage() : MainPageView(),
              );
            },
          );
        },
      ),
    );
  }
}
