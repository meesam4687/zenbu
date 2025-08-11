import 'package:al_client/components/global/item_card.dart';
import 'package:flutter/material.dart';

class CharacterRelations extends StatelessWidget {
  const CharacterRelations({super.key, required this.relations});

  final List relations;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Relations",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 260,
            width: double.infinity,
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relations.length,
                itemBuilder: (context, index) {
                  return ItemCard(
                    title:
                        ((relations[index]["title"]["romaji"] as String)
                                .length >
                            16)
                        ? '${(relations[index]["title"]["romaji"] as String).substring(0, 16)}...'
                        : (relations[index]["title"]["romaji"] as String),
                    image: relations[index]["coverImage"]["extraLarge"],
                    id: relations[index]["id"],
                    type: relations[index]["type"].toString().toLowerCase(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
