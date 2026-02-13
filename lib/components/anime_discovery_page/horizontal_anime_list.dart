import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/pages/entire_list_view.dart';
import 'package:flutter/cupertino.dart';

class HorizontalAnimeList extends StatelessWidget {
  const HorizontalAnimeList({
    super.key,
    required this.heading,
    required this.animeArray,
    required this.pagetype,
  });
  final String heading;
  final List animeArray;
  final PageType pagetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 305,
      width: double.infinity,
      margin: EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(heading, style: TextStyle(fontSize: 20)),
              CupertinoButton(
                padding: EdgeInsets.symmetric(horizontal: 10),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) {
                        return EntireListView(heading: heading, type: pagetype);
                      },
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('View All  '), Icon(CupertinoIcons.arrow_right)],
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 12),
            width: double.infinity,
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: animeArray.length,
              itemBuilder: (context, index) {
                final Map anime = animeArray[index];
                return Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: ItemCard(
                    title: anime["title"]["romaji"],
                    image: anime["coverImage"]["large"],
                    id: anime["id"],
                    type: anime["type"].toString().toLowerCase(),
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
