import 'package:zenbu/pages/list_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/main_page_view.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

class MediaList extends StatelessWidget {
  const MediaList({
    super.key,
    required this.items,
    required this.isAnime,
    this.multiRow = false,
    this.title,
  });

  final List<dynamic> items;
  final bool isAnime;
  final bool multiRow;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      width: double.infinity,
      height: multiRow ? 536 : 288,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 6.0,
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title ??
                        (isAnime ? "Currently Watching" : "Currently Reading"),
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (title == null)
                    MaterialButton(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ListPage(
                                title: isAnime ? "Anime List" : "Manga List",
                                mediaListType: isAnime
                                    ? MediaType.anime
                                    : MediaType.manga,
                              );
                            },
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('View All  '),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          items.isEmpty
              ? Container(
                  width: double.infinity,
                  height: multiRow ? 496 : 248,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAnime
                            ? Icons.tv_off_outlined
                            : Icons.menu_book_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Such empty",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () {
                          final mainPageState = context
                              .findAncestorStateOfType<MainPageViewState>();
                          if (mainPageState != null) {
                            mainPageState.changeTab(isAnime ? 0 : 2);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAnime
                                    ? Icons.arrow_back
                                    : Icons.arrow_forward,
                                size: 28,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Browse",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: multiRow ? 496 : 248,
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  child: Consumer<StateProvider>(
                    builder: (context, provider, _) {
                      if (multiRow) {
                        return GridView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 113,
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                              ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final int id = item['media']['id'];
                            final mediaListEntry =
                                item["media"]["mediaListEntry"] as Map?;
                            final progress = mediaListEntry?["progress"];
                            final String mediaType =
                                item["media"]["type"]
                                    ?.toString()
                                    .toLowerCase() ??
                                (isAnime ? "anime" : "manga");
                            final bool isItemAnime = mediaType == "anime";

                            final total = isItemAnime
                                ? (item["media"]["episodes"] ?? '?')
                                : (item["media"]["chapters"] ?? '?');
                            final stateText = progress != null
                                ? "$progress/$total"
                                : (item["media"]["meanScore"] != null
                                      ? "${item["media"]["meanScore"]}%"
                                      : "$total ${isItemAnime ? 'eps' : 'ch'}");

                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: ItemCard(
                                type: mediaType,
                                id: id,
                                title: provider.resolveTitle(
                                  item["media"]["title"] as Map?,
                                ),
                                state: stateText,
                                image:
                                    item["media"]["coverImage"]["extraLarge"]
                                        as String,
                                mediaListEntry: mediaListEntry,
                                listDataPreloaded: true,
                              ),
                            );
                          },
                        );
                      } else {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final int id = item['media']['id'];
                            final mediaListEntry =
                                item["media"]["mediaListEntry"] as Map?;
                            final progress = mediaListEntry?["progress"];
                            final String mediaType =
                                item["media"]["type"]
                                    ?.toString()
                                    .toLowerCase() ??
                                (isAnime ? "anime" : "manga");
                            final bool isItemAnime = mediaType == "anime";

                            final total = isItemAnime
                                ? (item["media"]["episodes"] ?? '?')
                                : (item["media"]["chapters"] ?? '?');
                            final stateText = progress != null
                                ? "$progress/$total"
                                : (item["media"]["meanScore"] != null
                                      ? "${item["media"]["meanScore"]}%"
                                      : "$total ${isItemAnime ? 'eps' : 'ch'}");

                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: ItemCard(
                                type: mediaType,
                                id: id,
                                title: provider.resolveTitle(
                                  item["media"]["title"] as Map?,
                                ),
                                state: stateText,
                                image:
                                    item["media"]["coverImage"]["extraLarge"]
                                        as String,
                                mediaListEntry: mediaListEntry,
                                listDataPreloaded: true,
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
