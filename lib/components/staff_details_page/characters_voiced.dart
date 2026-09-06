import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';

class CharactersVoiced extends StatelessWidget {
  const CharactersVoiced({super.key, required this.characters});

  final List characters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Characters Voiced',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 230,
            width: double.infinity,
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final character = characters[index];
                  final fullName = character['name']?['full'] as String?;
                  final name = (fullName != null)
                      ? (fullName.length > 16)
                            ? '${fullName.substring(0, 16)}...'
                            : fullName
                      : 'N/A';
                  return ItemCard(
                    title: name,
                    image: character['image']?['large'],
                    id: character['id'],
                    type: 'character',
                    state: character['role'],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
