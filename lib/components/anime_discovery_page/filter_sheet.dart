import 'package:flutter/cupertino.dart';
import 'package:zenbu/components/global/tags_genres_list.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

late Set<String> selectedGenres;
late Set<String> selectedtags;

class _FilterSheetState extends State<FilterSheet> {
  @override
  void initState() {
    selectedGenres = {};
    selectedtags = {};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(10)),
            Container(
              margin: EdgeInsets.all(15),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Genre",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Padding(padding: const EdgeInsets.all(10)),
                  Wrap(
                    spacing: 8,
                    children: genres.map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minSize: 0,
                        color: isSelected ? CupertinoColors.activeBlue : null,
                        borderRadius: BorderRadius.circular(20),
                        onPressed: () {
                          setState(() {
                            isSelected
                                ? selectedGenres.remove(genre)
                                : selectedGenres.add(genre);
                          });
                        },
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
