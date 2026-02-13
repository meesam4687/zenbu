import 'package:zenbu/pages/manga_search_page.dart';
import 'package:flutter/cupertino.dart';

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
              controller: TextEditingController(text: (searchText) ?? ""),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  (!Navigator.of(context).canPop())
                      ? Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  return SearchPage(query: value);
                                },
                          ),
                        )
                      : Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
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
            child: CupertinoButton.filled(
              padding: EdgeInsets.zero,
              minSize: 56,
              onPressed: () {},
              child: Container(
                width: 80,
                height: 56,
                alignment: Alignment.center,
                child: Icon(CupertinoIcons.slider_horizontal_3, size: 27),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
