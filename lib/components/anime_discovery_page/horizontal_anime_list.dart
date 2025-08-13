import 'package:al_client/components/global/item_card.dart';
import 'package:flutter/material.dart';

class HorizontalAnimeList extends StatelessWidget {
  const HorizontalAnimeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      margin: EdgeInsets.only(left: 15, right: 15, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Popular this Season", style: TextStyle(fontSize: 23)),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ItemCard(
                    title: "Dandadan Season 2",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx185660-uB8RUMBGovGr.jpg",
                    id: 0001,
                    type: "anime",
                  ),
                  ItemCard(
                    title: "Sono Bisque Doll wa Koi wo Suru...",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154768-DHHvNd4MjV1p.jpg",
                    id: 0001,
                    type: "anime",
                  ),
                  ItemCard(
                    title: "Gachiakuta",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx178025-cWJKEsZynkil.jpg",
                    id: 0001,
                    type: "anime",
                  ),
                  ItemCard(
                    title: "Kaoru Hana wa Rin to Saku",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx181444-Ut9DDUZdfHwg.jpg",
                    id: 0001,
                    type: "anime",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
