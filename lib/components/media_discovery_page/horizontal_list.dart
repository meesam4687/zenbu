import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/pages/entire_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

class HorizontalList extends StatelessWidget {
  const HorizontalList({
    super.key,
    required this.heading,
    required this.mediaArray,
    required this.pagetype,
  });

  final String heading;
  final List mediaArray;
  final PageType pagetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      width: double.infinity,
      margin: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(heading, style: const TextStyle(fontSize: 20)),
              MaterialButton(
                padding: const EdgeInsets.only(left: 10, right: 10),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return EntireListView(heading: heading, type: pagetype);
                      },
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('View All  '), Icon(Icons.arrow_forward)],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: double.infinity,
            height: 230,
            child: Consumer<StateProvider>(
              builder: (context, provider, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaArray.length,
                  itemBuilder: (context, index) {
                    final Map media = mediaArray[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: ItemCard(
                        title: provider.resolveTitle(media["title"] as Map?),
                        image: media["coverImage"]["large"] ?? '',
                        id: media["id"],
                        type: media["type"].toString().toLowerCase(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
