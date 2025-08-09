import 'dart:ui';
import 'package:flutter/material.dart';

class TitlePane extends StatelessWidget {
  const TitlePane({
    super.key,
    required this.title,
    required this.progress,
    required this.cover,
    required this.banner,
  });
  final String title;
  final String progress;
  final String cover;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: (banner == null)
                ? Container()
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Image.network(banner as String, fit: BoxFit.cover),
                  ),
          ),
          Scaffold(backgroundColor: surfaceColor.withAlpha(120)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, surfaceColor],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 90),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 180,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          cover,
                          fit: BoxFit.cover,
                          height: 180,
                          width: 127.38,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Text(title, style: TextStyle(fontSize: 27)),
                          ),
                          Text(progress),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(left: 12, right: 12, top: 10),
                  child: FilledButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 5,
                      children: [Icon(Icons.add), Text("Add to List")],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
