import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';
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
    final provider = Provider.of<StateProvider>(context);
    final displayAdultContent = provider.displayAdultContent;

    return FutureBuilder(
      future: simulcastData,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (asyncSnapshot.hasError || asyncSnapshot.data == null) {
          return const Center(child: Text("Error loading simulcasts"));
        }
        Map data = asyncSnapshot.data!;

        List airingSchedules =
            data["data"]?["Page"]?["airingSchedules"] as List? ?? [];
        if (!displayAdultContent) {
          airingSchedules = airingSchedules.where((item) {
            final media = item["media"];
            final isAdult = media != null
                ? (media["isAdult"] as bool? ?? false)
                : false;
            return !isAdult;
          }).toList();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: GridView.builder(
            itemCount: airingSchedules.length,
            gridDelegate: const ConstantSliverGridDelegate(
              itemWidth: 110.0,
              itemHeight: 230.0,
            ),
            itemBuilder: (context, index) {
              final schedule = airingSchedules[index];
              final media = schedule["media"] ?? {};
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: ItemCard(
                    title: provider.resolveTitle(media["title"] as Map?),
                    image: media["coverImage"]?["large"] ?? "",
                    id: media["id"],
                    type: "anime",
                    state: "Episode: ${schedule["episode"].toString()}",
                    mediaListEntry: media["mediaListEntry"] as Map?,
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
