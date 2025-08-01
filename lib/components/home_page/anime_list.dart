import 'package:flutter/material.dart';
import 'package:al_client/components/global/item_card.dart';

class AnimeList extends StatelessWidget {
  const AnimeList({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> items = [
      {
        "title": "Ligma the First",
        "image":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177937-HDZQqDqXQqxs.jpg",
        "state": "2/23",
      },
      {
        "title": "Ligma the Second",
        "image":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177686-9CwCvp3mkDI3.jpg",
        "state": "3/12",
      },
      {
        "title": "Ligma the Third",
        "image":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx132776-U34wk1Zbx7pU.png",
        "state": "5/11",
      },
      {
        "title": "Ligma the Fourth",
        "image":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx186052-zq8h0Qo0O0sP.jpg",
        "state": "7/12",
      },
      {
        "title": "Ligma the Fifth",
        "image":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx196063-hDLoZ2anG97G.png",
        "state": "8/13",
      },
    ];

    return Container(
      margin: EdgeInsets.only(top: 40),
      width: double.infinity,
      height: 320,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 6.0,
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Currently Watching", style: TextStyle(fontSize: 20)),
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
            ),
          ),
          Container(
            width: double.infinity,
            height: 260,
            margin: EdgeInsets.only(left: 12, right: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ItemCard(
                  title: item["title"] as String,
                  state: item["state"] as String,
                  image: item["image"] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
