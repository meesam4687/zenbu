import 'package:zenbu/pages/authentication_page.dart';
import 'package:zenbu/pages/notification_page.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:zenbu/authentication_token_controller.dart';
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
                      color: CupertinoTheme.of(context).primaryColor,
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
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => NotificationPage()),
              );
            },
            child: Container(
              height: 70,
              margin: EdgeInsets.only(left: 45),
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bell),
                  Padding(padding: EdgeInsetsGeometry.only(left: 20)),
                  Text("Notifications", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: Text("Logout"),
                    content: Text("Do you want to log out?"),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
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
                            CupertinoPageRoute(
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
                  Icon(CupertinoIcons.square_arrow_right),
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
