import 'package:al_client/pages/list_page.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:al_client/components/global/item_card.dart';

class MangaList extends StatelessWidget {
  const MangaList({super.key, required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
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
                  Text("Currently Reading", style: TextStyle(fontSize: 20)),
                  MaterialButton(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return SharedAxisTransition(
                                  animation: animation,
                                  secondaryAnimation: secondaryAnimation,
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                  child: const ListPage(title: "Manga List"),
                                );
                              },
                        ),
                      );
                    },
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
                  type: "manga",
                  id: id,
                  title:
                      ((item["media"]["title"]["romaji"] as String).length > 32)
                      ? '${(item["media"]["title"]["romaji"] as String).substring(0, 32)}...'
                      : item["media"]["title"]["romaji"] as String,
                  state:
                      "${item["media"]["mediaListEntry"]["progress"]}/${(item["media"]["chapters"] == null) ? '?' : item["media"]["chapters"]}",
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
