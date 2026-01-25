import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';

class ListPageView extends StatelessWidget {
  const ListPageView({super.key, required this.list, required this.mediaType});
  final List list;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10, left: 10, right: 10),
      child: GridView.builder(
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 137.142,
          childAspectRatio: 100 / 200,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: 3.0),
            child: ItemCard(
              title: (list[index]["media"]["title"]["romaji"] as String),
              image: list[index]["media"]["coverImage"]["extraLarge"],
              id: list[index]["media"]["id"],
              type: mediaType,
            ),
          );
        },
      ),
    );
  }
}
