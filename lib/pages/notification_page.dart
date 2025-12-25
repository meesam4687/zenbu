import 'package:al_client/components/notification_page/notification_card.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: Container(
        margin: EdgeInsets.all(15),
        width: double.infinity,
        child: Column(children: [NotificationCard()]),
      ),
    );
  }
}
