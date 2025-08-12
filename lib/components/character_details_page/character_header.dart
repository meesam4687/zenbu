import 'package:flutter/material.dart';

class CharacterHeader extends StatelessWidget {
  const CharacterHeader({
    super.key,
    required this.characterImage,
    required this.characterName,
    required this.characterSecondaryNames,
  });

  final String characterImage;
  final String characterName;
  final String characterSecondaryNames;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              height: 280,
              characterImage,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Text(
                  characterName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                Text(
                  characterSecondaryNames.length > 40
                      ? '${characterSecondaryNames.substring(0, 40)}...'
                      : characterSecondaryNames,
                  style: TextStyle(fontWeight: FontWeight.w200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
