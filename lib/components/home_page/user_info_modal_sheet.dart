import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/pages/notification_page.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserInfoModalSheet extends StatefulWidget {
  const UserInfoModalSheet({
    super.key,
    required this.profileImage,
    required this.username,
    required this.userId,
  });
  final String profileImage;
  final String username;
  final int userId;

  @override
  State<UserInfoModalSheet> createState() => _UserInfoModalSheetState();
}

class _UserInfoModalSheetState extends State<UserInfoModalSheet> {
  bool _isChecking = false;
  UpdateInfo? _updateInfo;
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkCachedUpdate();
  }

  Future<void> _checkCachedUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString('cached_update_version');
    final cachedChangelog = prefs.getString('cached_update_changelog');
    final cachedUrl = prefs.getString('cached_update_url');

    if (cachedVersion != null && cachedChangelog != null && cachedUrl != null) {
      setState(() {
        _hasUpdate = true;
        _updateInfo = UpdateInfo(
          remoteVersion: cachedVersion,
          changelog: cachedChangelog,
          downloadUrl: cachedUrl,
        );
      });
    }
  }

  Future<void> _runCheck({bool silent = false}) async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    final info = await UpdateService.checkUpdate(force: true);
    final prefs = await SharedPreferences.getInstance();

    if (info != null) {
      await prefs.setString('cached_update_version', info.remoteVersion);
      await prefs.setString('cached_update_changelog', info.changelog);
      await prefs.setString('cached_update_url', info.downloadUrl);

      if (mounted) {
        setState(() {
          _hasUpdate = true;
          _updateInfo = info;
        });
      }
    } else {
      await prefs.remove('cached_update_version');
      await prefs.remove('cached_update_changelog');
      await prefs.remove('cached_update_url');

      if (mounted) {
        setState(() {
          _hasUpdate = false;
          _updateInfo = null;
        });
        if (!silent) {
          Fluttertoast.showToast(
            msg: "App is up to date!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _hasUpdate ? 490 : 430,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(360)),
                  ),
                  child: CustomImage(
                    height: 70,
                    width: 70,
                    fit: BoxFit.fill,
                    imageUrl: widget.profileImage,
                    borderRadius: BorderRadius.circular(360),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(10)),
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(15)),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
            child: Container(
              height: 60,
              margin: const EdgeInsets.only(left: 45),
              width: double.infinity,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.notifications),
                  Padding(padding: EdgeInsets.only(left: 20)),
                  Text("Notifications", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ExtensionsPage()),
              );
            },
            child: Container(
              height: 60,
              margin: const EdgeInsets.only(left: 45),
              width: double.infinity,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.extension),
                  Padding(padding: EdgeInsets.only(left: 20)),
                  Text("Extensions", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          if (!_hasUpdate) ...[
            InkWell(
              onTap: _isChecking ? null : () => _runCheck(silent: false),
              child: Container(
                height: 60,
                margin: const EdgeInsets.only(left: 45, right: 20),
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.update),
                    const Padding(padding: EdgeInsets.only(left: 20)),
                    const Expanded(
                      child: Text(
                        "Check for Updates",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    if (_isChecking)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(
                left: 45,
                right: 20,
                top: 8,
                bottom: 8,
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.system_update_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Padding(padding: EdgeInsets.only(left: 20)),
                      Text(
                        "Update Available (${_updateInfo?.remoteVersion})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isChecking
                            ? null
                            : () => _runCheck(silent: false),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isChecking) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Text("Check Again"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  UpdatePage(updateInfo: _updateInfo!),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text("View Update"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Do you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          TokenStorage.clearTokens();
                          Provider.of<StateProvider>(
                            context,
                            listen: false,
                          ).alData = {};
                          Provider.of<StateProvider>(
                            context,
                            listen: false,
                          ).mangaDiscoveryData = {};
                          Provider.of<StateProvider>(
                            context,
                            listen: false,
                          ).animeDiscoveryData = {};
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => AuthenticationPage(),
                            ),
                          );
                        },
                        child: const Text("Yes"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              height: 60,
              margin: const EdgeInsets.only(left: 45),
              width: double.infinity,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  Padding(padding: EdgeInsets.only(left: 20)),
                  Text("Logout", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
