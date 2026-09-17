import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

class CharacterRelations extends StatelessWidget {
  const CharacterRelations({super.key, required this.relations});

  final List relations;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.relations,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 230,
            width: double.infinity,
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relations.length,
                itemBuilder: (context, index) {
                  final resolvedTitle = provider.resolveTitle(
                    relations[index]["node"]["title"] as Map?,
                    fallback: context.l10n.na,
                  );
                  final title = resolvedTitle.length > 16
                      ? '${resolvedTitle.substring(0, 16)}...'
                      : resolvedTitle;
                  final mediaListEntry =
                      relations[index]["node"]["mediaListEntry"] as Map?;
                  return ItemCard(
                    title: title,
                    image: relations[index]["node"]["coverImage"]["extraLarge"],
                    id: relations[index]["node"]["id"],
                    type: relations[index]["node"]["type"]
                        .toString()
                        .toLowerCase(),
                    state: relations[index]["staffRole"],
                    mediaListEntry: mediaListEntry,
                    listDataPreloaded: true,
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
