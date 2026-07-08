import 'package:flutter/material.dart';
import 'package:zenbu/components/global/item_card.dart';

class HorizontalStaffList extends StatelessWidget {
  const HorizontalStaffList({
    super.key,
    required this.title,
    required this.items,
    required this.unit,
  });

  final String title;
  final List<HorizontalStaffItem> items;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container();
    }

    return Container(
      height: 290,
      width: double.infinity,
      margin: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(title, style: const TextStyle(fontSize: 20))],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: double.infinity,
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 3.0),
                  child: ItemCard(
                    title: item.name,
                    image: item.imageUrl ?? "",
                    id: item.id,
                    type: title.toLowerCase().contains("studio")
                        ? "studio"
                        : "staff",
                    state: "${item.count} $unit",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalStaffItem {
  final String name;
  final String? imageUrl;
  final int count;
  final int id;

  const HorizontalStaffItem({
    required this.name,
    this.imageUrl,
    required this.count,
    required this.id,
  });
}
