import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.title,
    required this.state,
    required this.image,
  });
  final String? title;
  final String? state;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Material(
        child: Ink(
          height: 260,
          width: 141.32,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Ink.image(
                  image: NetworkImage(image as String),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  child: InkWell(onTap: () {}),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                state as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
