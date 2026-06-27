import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:zenbu/main.dart' as main_app;
import 'package:zenbu/main_page_view.dart';
import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/media_details_page.dart';
import 'package:zenbu/pages/staff_details_page.dart';

class DeepLinkController {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkController({required this.navigatorKey});

  void init() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  void _handleIncomingUri(Uri uri) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleDeepLink(uri);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void handleDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;

    if (uri.scheme == 'zenbu') {
      try {
        final fragment = uri.fragment;
        final params = Uri.splitQueryString(fragment);
        final tokenVal = params['access_token'];
        if (tokenVal != null) {
          await TokenStorage.saveTokens(accessToken: tokenVal);
          main_app.token = tokenVal;
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainPageView()),
            (route) => false,
          );
        } else {
          final parts = fragment.split("=");
          if (parts.length > 1) {
            final tokenVal = parts[1].split("&")[0];
            await TokenStorage.saveTokens(accessToken: tokenVal);
            main_app.token = tokenVal;
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainPageView()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        debugPrint('OAuth token parsing failed: $e');
      }
      return;
    }

    if ((uri.host == 'anilist.co' || uri.host == 'www.anilist.co') &&
        pathSegments.length >= 2) {
      final type = pathSegments[0].toLowerCase();
      final idString = pathSegments[1];
      final id = int.tryParse(idString);
      if (id == null) return;

      final savedToken = await TokenStorage.getAccessToken();
      if (savedToken == null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthenticationPage()),
          (route) => false,
        );
        return;
      }

      Widget page;
      switch (type) {
        case 'anime':
          page = MediaDetailsPage(id: id, isAnime: true);
          break;
        case 'manga':
          page = MediaDetailsPage(id: id, isAnime: false);
          break;
        case 'character':
          page = CharacterDetailsPage(id: id);
          break;
        case 'staff':
          page = StaffDetailsPage(id: id);
          break;
        default:
          return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }
}
