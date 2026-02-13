import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/components/character_details_page/character_description.dart';
import 'package:zenbu/components/character_details_page/character_header.dart';
import 'package:zenbu/components/character_details_page/character_relations.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/cupertino.dart';

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
          return const Center(child: CupertinoActivityIndicator());
        }
        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: true,
            onReload: () {
              setState(() {
                characterData = getStaffData(widget.id);
              });
            },
          );
        }
        final data = snapshot.data!;
        final secondaryNames = [
          if (data["data"]["Staff"]["name"]["native"] != null)
            data["data"]["Staff"]["name"]["native"],
          ...((data["data"]["Staff"]["name"]["alternative"] as List)),
        ];
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CharacterHeader(
                    characterImage: data["data"]["Staff"]["image"]["large"],
                    characterName: data["data"]["Staff"]["name"]["full"],
                    characterSecondaryNames: (secondaryNames).join(', '),
                  ),
                  CharacterDescription(
                    characterGender: (data["data"]["Staff"]["gender"] != null)
                        ? data["data"]["Staff"]["gender"]
                        : "N/A",
                    characterDescription:
                        (data["data"]["Staff"]["description"] != null)
                        ? data["data"]["Staff"]["description"]
                        : "",
                  ),
                  CharacterRelations(
                    relations:
                        data["data"]["Staff"]["staffMedia"]["nodes"] as List,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
