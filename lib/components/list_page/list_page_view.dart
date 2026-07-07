import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

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
      child: Consumer<StateProvider>(
        builder: (context, provider, _) {
          return GridView.builder(
            itemCount: list.length,
            gridDelegate: const ConstantSliverGridDelegate(
              itemWidth: 110.0,
              itemHeight: 226.0,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: ItemCard(
                    title: provider.resolveTitle(
                      list[index]["media"]["title"] as Map?,
                    ),
                    image: list[index]["media"]["coverImage"]["extraLarge"],
                    id: list[index]["media"]["id"],
                    type: mediaType,
                    mediaListEntry:
                        list[index]["media"]["mediaListEntry"] as Map?,
                    listDataPreloaded: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
