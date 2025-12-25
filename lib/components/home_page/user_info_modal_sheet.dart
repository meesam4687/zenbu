import 'package:al_client/pages/authentication_page.dart';
import 'package:al_client/pages/notification_page.dart';
import 'package:al_client/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:al_client/authentication_token_controller.dart';
import 'package:provider/provider.dart';

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
    return SizedBox(
      height: 340,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(360)),
                  ),
                  child: ClipOval(
                    child: Image(
                      height: 70,
                      width: 70,
                      fit: BoxFit.fill,
                      image: NetworkImage(profileImage),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsetsGeometry.all(10)),
                Text(
                  username,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsetsGeometry.all(15)),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
            child: Container(
              height: 70,
              margin: EdgeInsets.only(left: 45),
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.notifications),
                  Padding(padding: EdgeInsetsGeometry.only(left: 20)),
                  Text("Notifications", style: TextStyle(fontSize: 18)),
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
                    title: Text("Logout"),
                    content: Text("Do you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
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
                        child: Text("Yes"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              height: 70,
              margin: EdgeInsets.only(left: 45),
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  Padding(padding: EdgeInsetsGeometry.only(left: 20)),
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
