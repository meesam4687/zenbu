import 'package:al_client/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:al_client/main_page_view.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            debugShowCheckedModeBanner: false,
            title: 'ALC',
            theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
            darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
            themeMode: ThemeMode.system,
            home: const MainPageView(),
          );
        },
      ),
    );
  }
}
