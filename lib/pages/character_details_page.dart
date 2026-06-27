import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/character_details_page/character_description.dart';
import 'package:zenbu/components/character_details_page/character_header.dart';
import 'package:zenbu/components/character_details_page/character_relations.dart';
import 'package:zenbu/pages/error_page.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: true,
            message: snapshot.error?.toString(),
            onReload: () {
              setState(() {
                characterData = getCharacterData(widget.id);
              });
            },
          );
        }
        final data = snapshot.data!;
        final secondaryNames = [
          if (data["data"]["Character"]["name"]["native"] != null)
            data["data"]["Character"]["name"]["native"],
          ...((data["data"]["Character"]["name"]["alternative"] as List)),
        ];
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                CharacterHeader(
                  characterImage: data["data"]["Character"]["image"]["large"],
                  characterName: data["data"]["Character"]["name"]["full"],
                  characterSecondaryNames: (secondaryNames).join(', '),
                ),
                CharacterDescription(
                  characterGender: (data["data"]["Character"]["gender"] != null)
                      ? data["data"]["Character"]["gender"]
                      : "N/A",
                  characterDescription:
                      (data["data"]["Character"]["description"] != null)
                      ? data["data"]["Character"]["description"]
                      : "",
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
