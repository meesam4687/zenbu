import 'package:flutter/material.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';

class SimulcastPageView extends StatefulWidget {
  const SimulcastPageView({
    super.key,
    required this.epochLower,
    required this.epochUpper,
  });
  final int epochLower;
  final int epochUpper;
  @override
  State<SimulcastPageView> createState() => _SimulcastPageViewState();
}

class _SimulcastPageViewState extends State<SimulcastPageView>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> simulcastData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    simulcastData = getSimulcasts(widget.epochLower, widget.epochUpper);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: simulcastData,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        Map data = asyncSnapshot.data!;
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 10, left: 10, right: 10),
          child: GridView.builder(
            itemCount: (data["data"]["Page"]["airingSchedules"] as List).length,
            gridDelegate: const ConstantSliverGridDelegate(
              itemWidth: 110.0,
              itemHeight: 226.0,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: ItemCard(
                    title:
                        data["data"]["Page"]["airingSchedules"][index]["media"]["title"]["romaji"],
                    image:
                        data["data"]["Page"]["airingSchedules"][index]["media"]["coverImage"]["large"],
                    id: data["data"]["Page"]["airingSchedules"][index]["media"]["id"],
                    type: "anime",
                    state:
                        "Episode: ${data["data"]["Page"]["airingSchedules"][index]["episode"].toString()}",
                    mediaListEntry:
                        data["data"]["Page"]["airingSchedules"][index]["media"]["mediaListEntry"] as Map?,
                    listDataPreloaded: true,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
