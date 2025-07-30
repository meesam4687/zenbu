import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: ClipOval(
              child: Image(
                height: 40,
                width: 40,
                fit: BoxFit.fill,
                image: NetworkImage(
                  "https://fujiframe.com/assets/images/_3000x2000_fit_center-center_85_none/10085/xhs2-fuji-70-300-Amazilia-Hummingbird.webp",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
