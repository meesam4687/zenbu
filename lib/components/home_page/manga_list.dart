import 'package:flutter/material.dart';
import 'package:al_client/components/global/item_card.dart';

class MangaList extends StatelessWidget {
  const MangaList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
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
                  Text("Currently Reading", style: TextStyle(fontSize: 20)),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ItemCard(
                    title: "Ligma Balls the First",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177937-HDZQqDqXQqxs.jpg",
                    state: "1/20",
                  ),
                  ItemCard(
                    title: "Ligma Balls the Second",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx140291-JJnzSWCKSuPS.jpg",
                    state: "1/20",
                  ),
                  ItemCard(
                    title: "Ligma Balls the Third",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx180523-FjvW1XByUNMK.jpg",
                    state: "1/20",
                  ),
                  ItemCard(
                    title: "Ligma Balls the Fourth",
                    image:
                        "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx184322-TNA26Kg1I7Bd.jpg",
                    state: "1/20",
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
