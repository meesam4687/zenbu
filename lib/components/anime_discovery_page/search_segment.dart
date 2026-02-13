import 'package:zenbu/components/anime_discovery_page/filter_sheet.dart';
import 'package:zenbu/pages/anime_search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchSegment extends StatelessWidget {
  const SearchSegment({super.key, this.searchText});
  final String? searchText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 50, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              prefixIcon: Icon(CupertinoIcons.search),
              placeholder: "Search...",
              backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
              controller: TextEditingController(text: (searchText) ?? ""),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  (!Navigator.of(context).canPop())
                      ? Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) {
                              return SearchPage(query: value);
                            },
                          ),
                        )
                      : Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(
                            builder: (context) {
                              return SearchPage(query: value);
                            },
                          ),
                        );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return FilterSheet();
                  },
                );
              },
              child: Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).barBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.slider_horizontal_3, size: 27),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
