import 'package:flutter/material.dart';

class SearchSegment extends StatelessWidget {
  const SearchSegment({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 50, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              leading: Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: Icon(Icons.search),
              ),
              hintText: "Search...",
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilledButton(
              style: ButtonStyle(
                elevation: WidgetStatePropertyAll(6),
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onInverseSurface,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
                fixedSize: WidgetStatePropertyAll(Size(80, 56)),
                overlayColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              onPressed: () {},
              child: Icon(Icons.tune, size: 27),
            ),
          ),
        ],
      ),
    );
  }
}
