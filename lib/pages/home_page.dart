import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/home_page/anime_list.dart';
import 'package:al_client/components/home_page/manga_list.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> alData;
  @override
  void initState() {
    super.initState();
    alData = getHomePageData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text("Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () {},
              icon: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(360)),
                ),
                child: ClipOval(
                  child: FutureBuilder(
                    future: alData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 40,
                          width: 40,
                          child: Icon(Icons.face),
                        );
                      }
                      final data = snapshot.data!;
                      return Image(
                        height: 40,
                        width: 40,
                        fit: BoxFit.fill,
                        image: NetworkImage(
                          data['data']['Viewer']['avatar']['large'],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: alData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final data = snapshot.data!;
          final animeData = data["data"]["animeList"]["lists"][0]["entries"];
          final mangaData = data["data"]["mangaList"]["lists"][0]["entries"];
          return SingleChildScrollView(
            child: Column(
              children: [
                AnimeList(items: animeData),
                MangaList(items: mangaData),
              ],
            ),
          );
        },
      ),
    );
  }
}
