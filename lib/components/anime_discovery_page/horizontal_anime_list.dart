import 'package:al_client/components/global/item_card.dart';
import 'package:flutter/material.dart';

class HorizontalAnimeList extends StatelessWidget {
  const HorizontalAnimeList({
    super.key,
    required this.heading,
    required this.animeArray,
  });
  final String heading;
  final List animeArray;

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
          Container(
            margin: EdgeInsets.only(top: 12),
            width: double.infinity,
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: animeArray.length,
              itemBuilder: (context, index) {
                final Map anime = animeArray[index];
                return ItemCard(
                  title: anime["title"],
                  image: anime["coverImage"],
                  id: anime["id"],
                  type: anime["type"],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
