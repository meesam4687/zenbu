import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/character_details_page/character_description.dart';
import 'package:al_client/components/character_details_page/character_header.dart';
import 'package:al_client/components/character_details_page/character_relations.dart';
import 'package:flutter/material.dart';

class CharacterDetailsPage extends StatefulWidget {
  const CharacterDetailsPage({super.key, required this.id});

  final int id;

  @override
  State<CharacterDetailsPage> createState() => _CharacterDetailsPageState();
}

class _CharacterDetailsPageState extends State<CharacterDetailsPage> {
  late Future<Map<String, dynamic>> characterData;
  @override
  void initState() {
    characterData = getCharacterData(widget.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: characterData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final data = snapshot.data!;
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                CharacterHeader(
                  characterImage: data["data"]["Character"]["image"]["large"],
                  characterName: data["data"]["Character"]["name"]["full"],
                  characterSecondaryNames:
                      "${data["data"]["Character"]["name"]["native"]}, ${(data["data"]["Character"]["name"]["alternative"] as List).join(", ")}",
                ),
                CharacterDescription(
                  characterGender: data["data"]["Character"]["gender"],
                  characterDescription:
                      data["data"]["Character"]["description"],
                ),
                CharacterRelations(
                  relations:
                      data["data"]["Character"]["media"]["nodes"] as List,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
