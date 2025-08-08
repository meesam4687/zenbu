import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/anime_details_page/details.dart';
import 'package:flutter/material.dart';
import 'package:al_client/components/global/item_card.dart';

class DetailsPane extends StatefulWidget {
  const DetailsPane({super.key, required this.mediaId});
  final int mediaId;

  @override
  State<DetailsPane> createState() => _DetailsPaneState();
}

class _DetailsPaneState extends State<DetailsPane> {
  late Future<Map<String, dynamic>> animeData;
  @override
  void initState() {
    super.initState();
    animeData = getAnimeData(widget.mediaId);
  }

  @override
  Widget build(BuildContext context) {
    Map<int, String> months = {
      1: "January",
      2: "February",
      3: "March",
      4: "April",
      5: "May",
      6: "June",
      7: "July",
      8: "August",
      9: "September",
      10: "October",
      11: "November",
      12: "December",
    };
    return FutureBuilder(
      future: animeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final Map data = snapshot.data!;
        final List<dynamic> tags = (data['data']['Media']['tags'] as List)
            .map((tag) => tag['name'] as String)
            .toList();
        final List<dynamic> genres = data['data']['Media']['genres'];
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            children: [
              Details(
                meanScore:
                    "${(data["data"]["Media"]["meanScore"] as int) / 10}/10",

                studios: data["data"]["Media"]["studios"]["nodes"][0]["name"],

                source:
                    "${(data["data"]["Media"]["source"] as String).substring(0, 1).toUpperCase()}${(data["data"]["Media"]["source"] as String).substring(1).toLowerCase()}"
                        .replaceAll("_", " "),

                format: data["data"]["Media"]["format"],

                episodes: data["data"]["Media"]["episodes"],

                episodeDuration: "${data["data"]["Media"]["duration"]}",

                status:
                    "${(data["data"]["Media"]["status"] as String).substring(0, 1).toUpperCase()}${(data["data"]["Media"]["status"] as String).substring(1).toLowerCase()}",

                startDate:
                    "${months[data["data"]["Media"]["startDate"]["month"]]} ${data["data"]["Media"]["startDate"]["day"]}, ${data["data"]["Media"]["startDate"]["year"]}",

                endDate: (data["data"]["Media"]["endDate"]["day"] == null)
                    ? "N/A"
                    : "${months[data["data"]["Media"]["endDate"]["month"]]} ${data["data"]["Media"]["endDate"]["day"]}, ${data["data"]["Media"]["endDate"]["year"]}",

                season:
                    "${(data["data"]["Media"]["season"] as String).substring(0, 1).toUpperCase()}${(data["data"]["Media"]["season"] as String).substring(1).toLowerCase()}, ${data["data"]["Media"]["startDate"]["year"]}",
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: Text(
                        (data["data"]["Media"]["description"] as String)
                            .replaceAll(RegExp(r'<[^>]*>'), ''),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Genres and Tags",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (genres + tags).length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(label: Text((genres + tags)[index])),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Characters",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
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
                          itemCount:
                              (data["data"]["Media"]["characters"]["characters"]
                                      as List)
                                  .length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              title:
                                  data["data"]["Media"]["characters"]["characters"][index]["node"]["name"]["full"],
                              image:
                                  data["data"]["Media"]["characters"]["characters"][index]["node"]["image"]["large"],
                              id: data["data"]["Media"]["characters"]["characters"][index]["node"]["id"],
                              type: "character",
                              state:
                                  data["data"]["Media"]["characters"]["characters"][index]["role"],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Relations",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
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
                          itemCount:
                              (data["data"]["Media"]["relations"]["edges"]
                                      as List)
                                  .length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              id: data["data"]["Media"]["relations"]["edges"][index]["node"]["id"],
                              type:
                                  data["data"]["Media"]["relations"]["edges"][index]["node"]["type"]
                                      .toString()
                                      .toLowerCase(),
                              title:
                                  ((data["data"]["Media"]["relations"]["edges"][index]["node"]["title"]["romaji"]
                                              as String)
                                          .length >
                                      16)
                                  ? '${(data["data"]["Media"]["relations"]["edges"][index]["node"]["title"]["romaji"] as String).substring(0, 16)}...'
                                  : (data["data"]["Media"]["relations"]["edges"][index]["node"]["title"]["romaji"]
                                        as String),
                              image:
                                  data["data"]["Media"]["relations"]["edges"][index]["node"]["coverImage"]["extraLarge"],
                              state:
                                  data["data"]["Media"]["relations"]["edges"][index]["relationType"],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Staff",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
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
                          itemCount:
                              (data["data"]["Media"]["staff"]["edges"] as List)
                                  .length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              id: data["data"]["Media"]["staff"]["edges"][index]["id"],
                              type: "staff",
                              title:
                                  ((data["data"]["Media"]["staff"]["edges"][index]["node"]["name"]["full"]
                                              as String)
                                          .length >
                                      16)
                                  ? '${(data["data"]["Media"]["staff"]["edges"][index]["node"]["name"]["full"] as String).substring(0, 16)}...'
                                  : (data["data"]["Media"]["staff"]["edges"][index]["node"]["name"]["full"]
                                        as String),
                              image:
                                  data["data"]["Media"]["staff"]["edges"][index]["node"]["image"]["large"],
                              state:
                                  data["data"]["Media"]["staff"]["edges"][index]["role"],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recommendations",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
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
                          itemCount:
                              (data["data"]["Media"]["recommendations"]["edges"]
                                      as List)
                                  .length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              id: data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["id"],
                              type:
                                  (data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["type"]
                                          as String)
                                      .toLowerCase(),
                              title:
                                  ((data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["title"]["romaji"]
                                              as String)
                                          .length >
                                      16)
                                  ? '${(data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["title"]["romaji"] as String).substring(0, 16)}...'
                                  : (data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["title"]["romaji"]
                                        as String),
                              image:
                                  data["data"]["Media"]["recommendations"]["edges"][index]["node"]["media"]["coverImage"]["extraLarge"],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
