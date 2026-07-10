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
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:zenbu/services/discord_service.dart';

class DeepLinkController {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkController({required this.navigatorKey});

  void init() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    });
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

    if (uri.scheme == 'mangayomi' && uri.host == 'add-repo') {
      final params = uri.queryParameters;
      final repoName = params['repo_name'] ?? 'Community Repo';
      final repoUrl = params['repo_url'];
      final animeUrl = params['anime_url'];
      final mangaUrl = params['manga_url'];

      if (animeUrl == null && mangaUrl == null) {
        Fluttertoast.showToast(msg: 'No valid extension URL found in link.');
        return;
      }

      try {
        int addedCount = 0;
        if (animeUrl != null) {
          final suffix = (mangaUrl != null) ? ' (Anime)' : '';
          await RepoService.addRepo(
            animeUrl,
            customName: '$repoName$suffix',
            customWebsite: repoUrl,
          );
          addedCount++;
        }
        if (mangaUrl != null) {
          final suffix = (animeUrl != null) ? ' (Manga)' : '';
          await RepoService.addRepo(
            mangaUrl,
            customName: '$repoName$suffix',
            customWebsite: repoUrl,
          );
          addedCount++;
        }

        if (addedCount > 0) {
          Fluttertoast.showToast(msg: 'Added repository: $repoName');

          final savedToken = await TokenStorage.getAccessToken();
          if (savedToken != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const ExtensionsPage()),
            );
          } else {
            Fluttertoast.showToast(
              msg: 'Log in to view and install extensions!',
            );
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to add repository: $e');
      }
      return;
    }

    if (uri.scheme == 'discord-1525102908377530468') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        DiscordService.handleAuthCode(code);
      }
      return;
    }

    if (uri.scheme == 'zenbu') {
      if (uri.host == 'discord-auth') {
        final code = uri.queryParameters['code'];
        if (code != null) {
          DiscordService.handleAuthCode(code);
        }
        return;
      }

      if (uri.host == 'update') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final v = prefs.getString('cached_update_version');
          final c = prefs.getString('cached_update_changelog');
          final u = prefs.getString('cached_update_url');
          if (v != null && c != null && u != null) {
            final info = UpdateInfo(
              remoteVersion: v,
              changelog: c,
              downloadUrl: u,
            );
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => UpdatePage(updateInfo: info),
              ),
            );
          }
        } catch (e) {
          debugPrint('Failed to open update page from deep link: $e');
        }
        return;
      }

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
