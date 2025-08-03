import 'package:flutter/material.dart';
import 'package:al_client/components/global/item_card.dart';

class AnimeList extends StatelessWidget {
  const AnimeList({super.key, required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 40),
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
                  Text("Currently Watching", style: TextStyle(fontSize: 20)),
                  MaterialButton(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    onPressed: () {},
                    child: Row(
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
            margin: EdgeInsets.only(left: 12, right: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final int id = item['id'];
                return ItemCard(
                  type: "anime",
                  id: id,
                  title:
                      ((item["media"]["title"]["romaji"] as String).length > 32)
                      ? '${(item["media"]["title"]["romaji"] as String).substring(0, 32)}...'
                      : item["media"]["title"]["romaji"] as String,
                  state:
                      "${item["media"]["mediaListEntry"]["progress"]}/${(item["media"]["episodes"] == null) ? '?' : item["media"]["episodes"]}",
                  image: item["media"]["coverImage"]["extraLarge"] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
