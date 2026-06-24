import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';

class ListPageView extends StatelessWidget {
  const ListPageView({super.key, required this.list, required this.mediaType});
  final List list;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mediaType == "anime"
                  ? Icons.tv_off_outlined
                  : Icons.menu_book_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              "Empty list",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: GridView.builder(
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 137.142,
          childAspectRatio: 100 / 200,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 3.0),
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
