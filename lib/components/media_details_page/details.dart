import 'package:flutter/material.dart';

class Details extends StatelessWidget {
  const Details({super.key, required this.items});

  final List<({String label, String? value})> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: items.map((item) {
        final isNextEpisode =
            item.label == "Next Episode in" ||
            (item.label.startsWith("Episode ") && item.label.endsWith(" in"));
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isNextEpisode ? FontWeight.bold : FontWeight.w300,
                color: isNextEpisode
                    ? Theme.of(context).colorScheme.surfaceTint
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                child: Text(
                  item.value ?? "N/A",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNextEpisode
                        ? Theme.of(context).colorScheme.surfaceTint
                        : null,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
