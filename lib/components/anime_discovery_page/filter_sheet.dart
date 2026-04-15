import 'package:flutter/material.dart';
import 'package:zenbu/components/global/tags_genres_list.dart';
import './filter_tags.dart' as f;

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.maxYear});

  final int maxYear;
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
            Padding(padding: EdgeInsetsGeometry.all(10)),
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
                  Padding(padding: EdgeInsetsGeometry.all(10)),
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
                  Padding(padding: EdgeInsetsGeometry.all(10)),
                  ExpansionTile(
                    shape: Border.all(color: Colors.transparent),
                    tilePadding: EdgeInsetsGeometry.all(0),
                    title: Text(
                      "Tags",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        height: 290,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          itemCount: f.tags.length,
                          itemBuilder: (context, index) {
                            final item = f.tags[index]["name"];
                            return Row(
                              children: [
                                Checkbox(
                                  value: selectedtags.contains(item),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      value!
                                          ? selectedtags.add(item)
                                          : selectedtags.remove(item);
                                    });
                                  },
                                ),
                                Text(item),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsetsGeometry.all(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Release Year",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(padding: EdgeInsetsGeometry.all(5)),
                          DropdownMenu(
                            width: MediaQuery.of(context).size.width * 0.44,
                            hintText: "Select year",
                            dropdownMenuEntries: [
                              DropdownMenuEntry(
                                value: "CURRENT",
                                label: "Watching",
                              ),
                            ],
                            onSelected: (value) {},
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Country of Origin",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(padding: EdgeInsetsGeometry.all(5)),
                          DropdownMenu(
                            width: MediaQuery.of(context).size.width * 0.44,
                            hintText: "Select country",
                            dropdownMenuEntries: [
                              DropdownMenuEntry(
                                value: "CURRENT",
                                label: "Watching",
                              ),
                            ],
                            onSelected: (value) {},
                          ),
                        ],
                      ),
                    ],
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
