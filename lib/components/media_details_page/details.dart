import 'package:flutter/material.dart';

class Details extends StatelessWidget {
  const Details({super.key, required this.items});

  final List<({String label, String? value})> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: items.map((item) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              item.value ?? "N/A",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }
}
