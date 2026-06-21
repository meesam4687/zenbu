import 'package:zenbu/pages/list_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/item_card.dart';

class MediaList extends StatelessWidget {
  const MediaList({super.key, required this.items, required this.isAnime});

  final List<dynamic> items;
  final bool isAnime;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: isAnime ? 12 : 0),
      width: double.infinity,
      height: 320,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 6.0,
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAnime ? "Currently Watching" : "Currently Reading",
                    style: const TextStyle(fontSize: 20),
                  ),
                  MaterialButton(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ListPage(
                              title: isAnime ? "Anime List" : "Manga List",
                              mediaListType: isAnime
                                  ? MediaType.anime
                                  : MediaType.manga,
                            );
                          },
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('View All  '), Icon(Icons.arrow_forward)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 260,
            margin: const EdgeInsets.only(left: 12, right: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final int id = item['media']['id'];
                final progress = item["media"]["mediaListEntry"]["progress"];
                final total = isAnime
                    ? (item["media"]["episodes"] ?? '?')
                    : (item["media"]["chapters"] ?? '?');

                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: ItemCard(
                    type: isAnime ? "anime" : "manga",
                    id: id,
                    title: item["media"]["title"]["romaji"] as String,
                    state: "$progress/$total",
                    image: item["media"]["coverImage"]["extraLarge"] as String,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
