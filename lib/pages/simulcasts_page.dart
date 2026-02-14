import 'package:flutter/material.dart';
import 'package:zenbu/components/simulcasts_page/simulcast_page_view.dart';

List getScheduleEpochs() {
  double target =
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        0,
        0,
      ).millisecondsSinceEpoch /
      1000;

  List brackets = [];
  int weekday = DateTime.now().weekday;
  brackets.add([
    (weekday == 1) ? 7 : weekday - 1,
    target.toInt() - 86400,
    target.toInt(),
  ]);
  for (int i = 1; i < 7; i++) {
    brackets.add([
      weekday,
      target.toInt() + ((i - 1) * 86400),
      target.toInt() + (i * 86400),
    ]);
    weekday = weekday == 7 ? 1 : ++weekday;
  }
  return brackets;
}

class SimulcastsPage extends StatelessWidget {
  const SimulcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List epochs = getScheduleEpochs();
    List tabList = [];
    Map weekdays = {
      "1": "Monday",
      "2": "Tuesday",
      "3": "Wednesday",
      "4": "Thursday",
      "5": "Friday",
      "6": "Saturday",
      "7": "Sunday",
    };
    for (int i = 0; i < epochs.length; i++) {
      tabList.add(weekdays[epochs[i][0].toString()]);
    }
    return DefaultTabController(
      initialIndex: 1,
      length: 7,
      child: Scaffold(
        appBar: AppBar(title: Text("Simulcasts")),
        body: Column(
          children: [
            TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: [
                Tab(text: tabList[0]),
                Tab(text: tabList[1]),
                Tab(text: tabList[2]),
                Tab(text: tabList[3]),
                Tab(text: tabList[4]),
                Tab(text: tabList[5]),
                Tab(text: tabList[6]),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SimulcastPageView(
                    epochLower: epochs[0][1],
                    epochUpper: epochs[0][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[1][1],
                    epochUpper: epochs[1][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[2][1],
                    epochUpper: epochs[2][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[3][1],
                    epochUpper: epochs[3][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[4][1],
                    epochUpper: epochs[4][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[5][1],
                    epochUpper: epochs[5][2],
                  ),
                  SimulcastPageView(
                    epochLower: epochs[6][1],
                    epochUpper: epochs[6][2],
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
