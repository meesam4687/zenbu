import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';

class CharacterVAs extends StatelessWidget {
  const CharacterVAs({super.key, required this.vas});

  final List vas;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Voiced By",
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
                itemCount: vas.length,
                itemBuilder: (context, index) {
                  final name = (vas[index]["name"]["full"] != null)
                      ? ((vas[index]["name"]["full"] as String).length > 16)
                            ? '${(vas[index]["name"]["full"] as String).substring(0, 16)}...'
                            : (vas[index]["name"]["full"] as String)
                      : "N/A";
                  return ItemCard(
                    title: name,
                    image: vas[index]["image"]["large"],
                    id: vas[index]["id"],
                    type: "staff",
                    state: vas[index]["languageV2"],
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
