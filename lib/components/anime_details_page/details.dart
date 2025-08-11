import 'package:flutter/material.dart';

class Details extends StatelessWidget {
  const Details({
    super.key,
    required this.meanScore,
    required this.studios,
    required this.source,
    required this.format,
    required this.episodes,
    required this.episodeDuration,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.season,
  });
  final String meanScore;
  final String studios;
  final String source;
  final String format;
  final String? episodes;
  final String episodeDuration;
  final String status;
  final String startDate;
  final String endDate;
  final String season;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mean Score",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              meanScore,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Studios",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              studios,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              source,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Format",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              format,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Episodes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            (episodes == null)
                ? Text(
                    "N/A",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : Text(
                    episodes.toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Episode Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              episodeDuration,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              status,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Start Date",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              startDate,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "End Date",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              endDate,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Season",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            Text(
              season,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
