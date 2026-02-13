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
            Padding(padding: EdgeInsets.all(10)),
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
                  Padding(padding: EdgeInsets.all(10)),
                  Wrap(
                    spacing: 8,
                    children: genres.map((genre) {
                      return FilterChip(
                        label: Text(genre),
                        selected: selectedGenres.contains(genre),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedGenres.add(genre)
                                : selectedGenres.remove(genre);
                          });
                        },
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
