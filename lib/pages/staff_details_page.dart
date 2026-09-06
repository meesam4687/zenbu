import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/character_details_page/character_description.dart';
import 'package:zenbu/components/character_details_page/character_header.dart';
import 'package:zenbu/components/character_details_page/character_relations.dart';
import 'package:zenbu/components/staff_details_page/characters_voiced.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';

class StaffDetailsPage extends StatefulWidget {
  const StaffDetailsPage({super.key, required this.id});

  final int id;

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> {
  late Future<Map<String, dynamic>> characterData;
  @override
  void initState() {
    characterData = getStaffData(widget.id);
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
                characterData = getStaffData(widget.id);
              });
            },
          );
        }
        final data = snapshot.data!;
        final staff = data["data"]["Staff"];
        final secondaryNames = [
          if (staff["name"]["native"] != null) staff["name"]["native"],
          ...((staff["name"]["alternative"] as List)),
        ];

        final staffMediaRelations =
            staff["staffMedia"]?["edges"] as List? ?? [];

        final characterEdges = staff["characters"]?["edges"] as List? ?? [];
        final Map<int, dynamic> uniqueCharacters = {};
        for (var edge in characterEdges) {
          final characterNode = edge["node"];
          if (characterNode != null && characterNode["id"] != null) {
            uniqueCharacters[characterNode["id"]] = {
              ...characterNode,
              "role": edge["role"],
            };
          }
        }
        final voicedCharacters = uniqueCharacters.values.toList();

        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  CharacterHeader(
                    characterImage: staff["image"]["large"],
                    characterName: staff["name"]["full"],
                    characterSecondaryNames: (secondaryNames).join(', '),
                  ),
                  CharacterDescription(
                    characterGender: (staff["gender"] != null)
                        ? staff["gender"]
                        : "N/A",
                    characterDescription: (staff["description"] != null)
                        ? staff["description"]
                        : "",
                  ),
                  if (staffMediaRelations.isNotEmpty)
                    CharacterRelations(relations: staffMediaRelations),
                  if (voicedCharacters.isNotEmpty)
                    CharactersVoiced(characters: voicedCharacters),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
