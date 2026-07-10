import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final class DiscordString extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;
  @ffi.Size()
  external int size;
}

void _onDiscordStatusChanged(
  int status,
  int error,
  int errorDetail,
  ffi.Pointer<ffi.Void> userData,
) {
  if (error != 0) {
    debugPrint(
      "Discord status changed callback error: status=$status, error=$error, detail=$errorDetail",
    );
  }
  DiscordService.setConnectionStatus(status);
}

void _onDiscordTokenUpdated(
  ffi.Pointer<ffi.Void> result,
  ffi.Pointer<ffi.Void> userData,
) {}

void _onDiscordPresenceUpdated(
  ffi.Pointer<ffi.Void> result,
  ffi.Pointer<ffi.Void> userData,
) {}

class PendingPresenceUpdate {
  final bool isManga;
  final String title;
  final String details;
  final String? imageUrl;
  final int? mediaId;

  PendingPresenceUpdate({
    required this.isManga,
    required this.title,
    required this.details,
    this.imageUrl,
    this.mediaId,
  });
}

class DiscordService {
  static const String clientId = "1525102908377530468";
  static const String redirectUri = "https://cdn.meesam.dev/zenbu-discord";

  static int _connectionStatus = 0;
  static PendingPresenceUpdate? _pendingUpdate;

  static void setConnectionStatus(int status) {
    _connectionStatus = status;
    if (status == 3 && _pendingUpdate != null) {
      final pending = _pendingUpdate!;
      _pendingUpdate = null;
      debugPrint(
        "Discord ready. Sending pending presence update for: ${pending.title}",
      );
      if (pending.isManga) {
        updateReadingStatus(
          mangaTitle: pending.title,
          chapterDetails: pending.details,
          imageUrl: pending.imageUrl,
          mediaId: pending.mediaId,
        );
      } else {
        updateWatchingStatus(
          animeTitle: pending.title,
          episodeDetails: pending.details,
          imageUrl: pending.imageUrl,
          mediaId: pending.mediaId,
        );
      }
    }
  }

  static ffi.DynamicLibrary? _dylib;
  static ffi.Pointer<ffi.Void>? _core;
  static Timer? _callbackTimer;
  static bool _initialized = false;
  static final ValueNotifier<bool> discordLinked = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> presenceEnabled = ValueNotifier<bool>(true);

  static ffi.NativeCallable<
    ffi.Void Function(ffi.Int32, ffi.Int32, ffi.Int32, ffi.Pointer<ffi.Void>)
  >?
  _statusCallable;
  static ffi.NativeCallable<
    ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  >?
  _tokenCallable;
  static ffi.NativeCallable<
    ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  >?
  _presenceCallable;

  static late final void Function(ffi.Pointer<ffi.Void>) _clientInit;
  static late final void Function(ffi.Pointer<ffi.Void>, int)
  _clientSetApplicationId;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
  )
  _clientSetStatusChangedCallback;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    int,
    DiscordString,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
  )
  _clientUpdateToken;
  static late final void Function(ffi.Pointer<ffi.Void>) _clientConnect;
  static late final void Function(ffi.Pointer<ffi.Void>) _clientDisconnect;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
  )
  _clientUpdateRichPresence;
  static late final void Function(ffi.Pointer<ffi.Void>)
  _clientClearRichPresence;
  static late final void Function() _runCallbacks;
  static late final void Function(ffi.Pointer<ffi.Void>) _clientDrop;

  static late final void Function(ffi.Pointer<ffi.Void>) _activityInit;
  static late final void Function(ffi.Pointer<ffi.Void>) _activityDrop;
  static late final void Function(ffi.Pointer<ffi.Void>, DiscordString)
  _activitySetName;
  static late final void Function(ffi.Pointer<ffi.Void>, int) _activitySetType;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<DiscordString>,
  )
  _activitySetState;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<DiscordString>,
  )
  _activitySetDetails;
  static late final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  _activitySetAssets;
  static late final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  _activitySetTimestamps;

  static late final void Function(ffi.Pointer<ffi.Void>) _activityAssetsInit;
  static late final void Function(ffi.Pointer<ffi.Void>) _activityAssetsDrop;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<DiscordString>,
  )
  _activityAssetsSetLargeImage;
  static late final void Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<DiscordString>,
  )
  _activityAssetsSetLargeText;

  static late final void Function(ffi.Pointer<ffi.Void>)
  _activityTimestampsInit;
  static late final void Function(ffi.Pointer<ffi.Void>)
  _activityTimestampsDrop;
  static late final void Function(ffi.Pointer<ffi.Void>, int)
  _activityTimestampsSetStart;

  static late final void Function(ffi.Pointer<ffi.Void>) _activityButtonInit;
  static late final void Function(ffi.Pointer<ffi.Void>) _activityButtonDrop;
  static late final void Function(ffi.Pointer<ffi.Void>, DiscordString)
  _activityButtonSetLabel;
  static late final void Function(ffi.Pointer<ffi.Void>, DiscordString)
  _activityButtonSetUrl;
  static late final void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  _activityAddButton;

  static void loadLibrary() {
    if (_dylib != null) return;
    try {
      if (Platform.isAndroid) {
        try {
          _dylib = ffi.DynamicLibrary.open("libdiscord_partner_sdk.so");
        } catch (_) {
          try {
            _dylib = ffi.DynamicLibrary.open("libdiscord_game_sdk.so");
          } catch (_) {
            try {
              _dylib = ffi.DynamicLibrary.open("libdiscord_social_sdk.so");
            } catch (e) {
              debugPrint("Could not load Discord Social SDK .so files: $e");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to load Discord native SDK library: $e");
    }
  }

  static Future<bool> initialize() async {
    if (_initialized) return true;
    loadLibrary();

    final library = _dylib;
    if (library == null) {
      debugPrint("Discord SDK library not loaded.");
      return false;
    }

    try {
      _clientInit = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Client_Init");

      _clientSetApplicationId = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Uint64),
            void Function(ffi.Pointer<ffi.Void>, int)
          >("Discord_Client_SetApplicationId");

      _clientSetStatusChangedCallback = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            ),
            void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            )
          >("Discord_Client_SetStatusChangedCallback");

      _clientUpdateToken = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Int32,
              DiscordString,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            ),
            void Function(
              ffi.Pointer<ffi.Void>,
              int,
              DiscordString,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            )
          >("Discord_Client_UpdateToken");

      _clientConnect = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Client_Connect");

      _clientDisconnect = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Client_Disconnect");

      _clientUpdateRichPresence = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            ),
            void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
            )
          >("Discord_Client_UpdateRichPresence");

      _clientClearRichPresence = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Client_ClearRichPresence");

      _runCallbacks = library
          .lookupFunction<ffi.Void Function(), void Function()>(
            "Discord_RunCallbacks",
          );

      _clientDrop = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Client_Drop");

      _activityInit = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Activity_Init");

      _activityDrop = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_Activity_Drop");

      _activitySetName = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, DiscordString),
            void Function(ffi.Pointer<ffi.Void>, DiscordString)
          >("Discord_Activity_SetName");

      _activitySetType = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Int32),
            void Function(ffi.Pointer<ffi.Void>, int)
          >("Discord_Activity_SetType");

      _activitySetState = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<DiscordString>,
            ),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DiscordString>)
          >("Discord_Activity_SetState");

      _activitySetDetails = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<DiscordString>,
            ),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DiscordString>)
          >("Discord_Activity_SetDetails");

      _activitySetAssets = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >("Discord_Activity_SetAssets");

      _activitySetTimestamps = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >("Discord_Activity_SetTimestamps");

      _activityAssetsInit = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityAssets_Init");

      _activityAssetsDrop = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityAssets_Drop");

      _activityAssetsSetLargeImage = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<DiscordString>,
            ),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DiscordString>)
          >("Discord_ActivityAssets_SetLargeImage");

      _activityAssetsSetLargeText = library
          .lookupFunction<
            ffi.Void Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<DiscordString>,
            ),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DiscordString>)
          >("Discord_ActivityAssets_SetLargeText");

      _activityTimestampsInit = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityTimestamps_Init");

      _activityTimestampsDrop = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityTimestamps_Drop");

      _activityTimestampsSetStart = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Uint64),
            void Function(ffi.Pointer<ffi.Void>, int)
          >("Discord_ActivityTimestamps_SetStart");

      _activityButtonInit = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityButton_Init");

      _activityButtonDrop = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>)
          >("Discord_ActivityButton_Drop");

      _activityButtonSetLabel = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, DiscordString),
            void Function(ffi.Pointer<ffi.Void>, DiscordString)
          >("Discord_ActivityButton_SetLabel");

      _activityButtonSetUrl = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, DiscordString),
            void Function(ffi.Pointer<ffi.Void>, DiscordString)
          >("Discord_ActivityButton_SetUrl");

      _activityAddButton = library
          .lookupFunction<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>),
            void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >("Discord_Activity_AddButton");

      _core = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
      _clientInit(_core!);
      _clientSetApplicationId(_core!, int.parse(clientId));

      _statusCallable ??=
          ffi.NativeCallable<
            ffi.Void Function(
              ffi.Int32,
              ffi.Int32,
              ffi.Int32,
              ffi.Pointer<ffi.Void>,
            )
          >.listener(_onDiscordStatusChanged);
      _clientSetStatusChangedCallback(
        _core!,
        _statusCallable!.nativeFunction.cast<ffi.Void>(),
        ffi.nullptr,
        ffi.nullptr,
      );

      _initialized = true;

      _callbackTimer = Timer.periodic(const Duration(milliseconds: 250), (
        timer,
      ) {
        runCallbacks();
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("discord_token");
      if (token != null) {
        await connectWithToken(token);
      }

      return true;
    } catch (e) {
      debugPrint("Error initializing Discord SDK: $e");
      return false;
    }
  }

  static Future<void> connectWithToken(String token) async {
    if (!_initialized) {
      await initialize();
      return;
    }
    final client = _core;
    if (client == null) return;

    try {
      final tokenStruct = _toDiscordString(token);
      _tokenCallable ??=
          ffi.NativeCallable<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >.listener(_onDiscordTokenUpdated);

      _clientUpdateToken(
        client,
        1,
        tokenStruct.ref,
        _tokenCallable!.nativeFunction.cast<ffi.Void>(),
        ffi.nullptr,
        ffi.nullptr,
      );
      _clientConnect(client);
      _freeDiscordString(tokenStruct);
    } catch (e) {
      debugPrint("Error connecting to Discord with token: $e");
    }
  }

  static void runCallbacks() {
    if (!_initialized) return;
    try {
      _runCallbacks();
    } catch (e) {
      debugPrint("Error running Discord callbacks: $e");
    }
  }

  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url
        .encode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static Future<void> startAuthorizationFlow() async {
    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("discord_code_verifier", verifier);

    final url = Uri(
      scheme: 'https',
      host: 'discord.com',
      path: '/oauth2/authorize',
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid sdk.social_layer_presence',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Fluttertoast.showToast(msg: "Opening Discord for Authorization...");
      } else {
        Fluttertoast.showToast(msg: "Could not open authorization browser.");
      }
    } catch (e) {
      debugPrint("Error launching Discord auth: $e");
      Fluttertoast.showToast(msg: "Error opening authorization page: $e");
    }
  }

  static Future<bool> isLinked() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getBool("discord_linked") ?? false;
    discordLinked.value = linked;
    await isPresenceEnabled();
    return linked;
  }

  static Future<bool> isPresenceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("discord_presence_enabled") ?? true;
    presenceEnabled.value = enabled;
    return enabled;
  }

  static Future<void> setPresenceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("discord_presence_enabled", enabled);
    presenceEnabled.value = enabled;
    if (!enabled) {
      await clearPresence();
    }
  }

  static Future<void> setLinked(bool linked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("discord_linked", linked);
    discordLinked.value = linked;
  }

  static Future<void> unlink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("discord_token");
    await prefs.remove("discord_presence_enabled");
    presenceEnabled.value = true;
    await setLinked(false);
    dispose();
  }

  static Future<void> handleAuthCode(String code) async {
    Fluttertoast.showToast(msg: "Connecting to Discord...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final verifier = prefs.getString("discord_code_verifier");

      if (verifier == null) {
        Fluttertoast.showToast(msg: "OAuth2 code verifier missing.");
        return;
      }

      final response = await http.post(
        Uri.parse('https://discord.com/api/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
      );

      if (response.statusCode != 200) {
        debugPrint("Failed to exchange code: ${response.body}");
        Fluttertoast.showToast(msg: "Failed to link Discord account.");
        return;
      }

      final json = jsonDecode(response.body);
      final accessToken = json['access_token'] as String;

      await prefs.setString("discord_token", accessToken);
      await prefs.remove("discord_code_verifier");

      final success = await initialize();
      if (success) {
        await connectWithToken(accessToken);
        await setLinked(true);
        Fluttertoast.showToast(msg: "Discord Rich Presence Active!");
      } else {
        Fluttertoast.showToast(
          msg: "Failed to start Discord presence connection.",
        );
      }
    } catch (e) {
      debugPrint("Error exchanging auth code: $e");
      Fluttertoast.showToast(msg: "Error connecting to Discord.");
    }
  }

  static Future<void> updateWatchingStatus({
    required String animeTitle,
    required String episodeDetails,
    required String? imageUrl,
    required int? mediaId,
  }) async {
    if (!await isLinked() || !await isPresenceEnabled()) {
      return;
    }

    if (_connectionStatus != 3) {
      _pendingUpdate = PendingPresenceUpdate(
        isManga: false,
        title: animeTitle,
        details: episodeDetails,
        imageUrl: imageUrl,
        mediaId: mediaId,
      );

      if (!_initialized) {
        await initialize();
      }
      return;
    }

    final client = _core;
    if (client == null) {
      debugPrint("Discord Client not initialized.");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("discord_token");
      if (token == null) return;

      final activity = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
      _activityInit(activity);

      _activitySetType(activity, 3);

      final nameStr = _toDiscordString(animeTitle);
      _activitySetName(activity, nameStr.ref);

      final stateStr = _toDiscordString(episodeDetails);
      _activitySetState(activity, stateStr);

      final detailsStr = _toDiscordString(animeTitle);
      _activitySetDetails(activity, detailsStr);

      if (imageUrl != null) {
        final assets = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
        _activityAssetsInit(assets);

        final largeImgStr = _toDiscordString(imageUrl);
        _activityAssetsSetLargeImage(assets, largeImgStr);

        final largeTxtStr = _toDiscordString(animeTitle);
        _activityAssetsSetLargeText(assets, largeTxtStr);

        _activitySetAssets(activity, assets);

        _freeDiscordString(largeImgStr);
        _freeDiscordString(largeTxtStr);
        _activityAssetsDrop(assets);
        calloc.free(assets);
      }

      final timestamps = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
      _activityTimestampsInit(timestamps);
      _activityTimestampsSetStart(
        timestamps,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      _activitySetTimestamps(activity, timestamps);
      _activityTimestampsDrop(timestamps);
      calloc.free(timestamps);

      if (mediaId != null) {
        final button = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
        _activityButtonInit(button);

        final labelStr = _toDiscordString("Open in AniList");
        _activityButtonSetLabel(button, labelStr.ref);

        final urlStr = _toDiscordString("https://anilist.co/anime/$mediaId");
        _activityButtonSetUrl(button, urlStr.ref);

        _activityAddButton(activity, button);

        _freeDiscordString(labelStr);
        _freeDiscordString(urlStr);
        _activityButtonDrop(button);
        calloc.free(button);
      }

      _presenceCallable ??=
          ffi.NativeCallable<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >.listener(_onDiscordPresenceUpdated);
      _clientUpdateRichPresence(
        client,
        activity,
        _presenceCallable!.nativeFunction.cast<ffi.Void>(),
        ffi.nullptr,
        ffi.nullptr,
      );

      _freeDiscordString(nameStr);
      _freeDiscordString(stateStr);
      _freeDiscordString(detailsStr);
      _activityDrop(activity);
      calloc.free(activity);
    } catch (e) {
      debugPrint("Error updating Discord presence: $e");
    }
  }

  static Future<void> updateReadingStatus({
    required String mangaTitle,
    required String chapterDetails,
    required String? imageUrl,
    required int? mediaId,
  }) async {
    if (!await isLinked() || !await isPresenceEnabled()) {
      return;
    }

    if (_connectionStatus != 3) {
      _pendingUpdate = PendingPresenceUpdate(
        isManga: true,
        title: mangaTitle,
        details: chapterDetails,
        imageUrl: imageUrl,
        mediaId: mediaId,
      );

      if (!_initialized) {
        await initialize();
      }
      return;
    }

    final client = _core;
    if (client == null) {
      debugPrint("Discord Client not initialized.");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("discord_token");
      if (token == null) return;

      final activity = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
      _activityInit(activity);

      _activitySetType(activity, 3);

      final nameStr = _toDiscordString(mangaTitle);
      _activitySetName(activity, nameStr.ref);

      final stateStr = _toDiscordString(chapterDetails);
      _activitySetState(activity, stateStr);

      final detailsStr = _toDiscordString(mangaTitle);
      _activitySetDetails(activity, detailsStr);

      if (imageUrl != null) {
        final assets = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
        _activityAssetsInit(assets);

        final largeImgStr = _toDiscordString(imageUrl);
        _activityAssetsSetLargeImage(assets, largeImgStr);

        final largeTxtStr = _toDiscordString(mangaTitle);
        _activityAssetsSetLargeText(assets, largeTxtStr);

        _activitySetAssets(activity, assets);

        _freeDiscordString(largeImgStr);
        _freeDiscordString(largeTxtStr);
        _activityAssetsDrop(assets);
        calloc.free(assets);
      }

      final timestamps = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
      _activityTimestampsInit(timestamps);
      _activityTimestampsSetStart(
        timestamps,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      _activitySetTimestamps(activity, timestamps);
      _activityTimestampsDrop(timestamps);
      calloc.free(timestamps);

      if (mediaId != null) {
        final button = calloc<ffi.Pointer<ffi.Void>>().cast<ffi.Void>();
        _activityButtonInit(button);

        final labelStr = _toDiscordString("Open in AniList");
        _activityButtonSetLabel(button, labelStr.ref);

        final urlStr = _toDiscordString("https://anilist.co/manga/$mediaId");
        _activityButtonSetUrl(button, urlStr.ref);

        _activityAddButton(activity, button);

        _freeDiscordString(labelStr);
        _freeDiscordString(urlStr);
        _activityButtonDrop(button);
        calloc.free(button);
      }

      _presenceCallable ??=
          ffi.NativeCallable<
            ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
          >.listener(_onDiscordPresenceUpdated);
      _clientUpdateRichPresence(
        client,
        activity,
        _presenceCallable!.nativeFunction.cast<ffi.Void>(),
        ffi.nullptr,
        ffi.nullptr,
      );

      _freeDiscordString(nameStr);
      _freeDiscordString(stateStr);
      _freeDiscordString(detailsStr);
      _activityDrop(activity);
      calloc.free(activity);
    } catch (e) {
      debugPrint("Error updating Discord presence: $e");
    }
  }

  static Future<void> clearPresence() async {
    _pendingUpdate = null;
    if (!await isLinked()) return;
    if (!_initialized) return;

    final client = _core;
    if (client == null) return;

    try {
      _clientClearRichPresence(client);
    } catch (e) {
      debugPrint("Error clearing Discord presence: $e");
    }
  }

  static ffi.Pointer<DiscordString> _toDiscordString(String text) {
    final units = utf8.encode(text);
    final ptr = calloc<ffi.Uint8>(units.length);
    for (var i = 0; i < units.length; i++) {
      (ptr + i).value = units[i];
    }
    final ds = calloc<DiscordString>();
    ds.ref.ptr = ptr;
    ds.ref.size = units.length;
    return ds;
  }

  static void _freeDiscordString(ffi.Pointer<DiscordString> ds) {
    calloc.free(ds.ref.ptr);
    calloc.free(ds);
  }

  static void dispose() {
    _connectionStatus = 0;
    _pendingUpdate = null;
    _callbackTimer?.cancel();
    _statusCallable?.close();
    _statusCallable = null;
    _tokenCallable?.close();
    _tokenCallable = null;
    _presenceCallable?.close();
    _presenceCallable = null;
    final client = _core;
    if (client != null) {
      try {
        _clientDisconnect(client);
        _clientDrop(client);
      } catch (e) {
        debugPrint("Error destroying Discord Core: $e");
      }
    }
    _core = null;
    _initialized = false;
  }
}
