import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/pages/notification_page.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/authentication_token_controller.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:zenbu/pages/settings_page.dart';
import 'package:zenbu/pages/user_profile_page.dart';

class UserInfoModalSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: userId),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(360),
                          ),
                        ),
                        child: CustomImage(
                          height: 70,
                          width: 70,
                          fit: BoxFit.fill,
                          imageUrl: profileImage,
                          borderRadius: BorderRadius.circular(360),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  MaterialPageRoute(
                    builder: (context) => const ExtensionsPage(),
                  ),
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
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: Container(
                height: 60,
                margin: const EdgeInsets.only(left: 45),
                width: double.infinity,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.settings),
                    Padding(padding: EdgeInsets.only(left: 20)),
                    Text("Settings", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
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
      ),
    );
  }
}
