import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

class CharacterRelations extends StatelessWidget {
  const CharacterRelations({super.key, required this.relations});

  final List relations;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
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
                  final resolvedTitle = provider.resolveTitle(
                      relations[index]["node"]["title"] as Map?,
                      fallback: "N/A");
                  final title = resolvedTitle.length > 16
                      ? '${resolvedTitle.substring(0, 16)}...'
                      : resolvedTitle;
                  return ItemCard(
                    title: title,
                    image: relations[index]["node"]["coverImage"]["extraLarge"],
                    id: relations[index]["node"]["id"],
                    type: relations[index]["node"]["type"]
                        .toString()
                        .toLowerCase(),
                    state: relations[index]["staffRole"],
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
