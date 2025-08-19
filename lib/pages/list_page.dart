import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Column(
          children: [
            TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: const [
                Tab(text: "Current"),
                Tab(text: "Planning"),
                Tab(text: "Completed"),
                Tab(text: "Paused"),
                Tab(text: "Dropped"),
                Tab(text: "All"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text("Current")),
                  Center(child: Text("Planning")),
                  Center(child: Text("Completed")),
                  Center(child: Text("Paused")),
                  Center(child: Text("Dropped")),
                  Center(child: Text("All")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
