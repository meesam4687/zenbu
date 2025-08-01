import 'package:al_client/components/home_page/anime_list.dart';
import 'package:al_client/components/home_page/manga_list.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  child: Image(
                    height: 40,
                    width: 40,
                    fit: BoxFit.fill,
                    image: NetworkImage(
                      "https://img.freepik.com/free-vector/wall-frame-white-color_23-2147507923.jpg?semt=ais_hybrid&w=740&q=80",
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [AnimeList(), MangaList()]),
      ),
    );
  }
}
