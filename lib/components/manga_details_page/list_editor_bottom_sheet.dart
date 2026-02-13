import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ListEditorBottomSheet extends StatefulWidget {
  const ListEditorBottomSheet({
    super.key,
    required this.status,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.score,
    required this.repeatCount,
    required this.mediaId,
    required this.onUpdate,
  });

  final String status;
  final int progress;
  final Map startDate;
  final Map endDate;
  final double score;
  final int repeatCount;
  final int mediaId;
  final Function(String, int, Map) onUpdate;

  @override
  State<ListEditorBottomSheet> createState() => _ListEditorBottomSheetState();
}

class _ListEditorBottomSheetState extends State<ListEditorBottomSheet> {
  final TextEditingController chaptersController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  final TextEditingController rewatchController = TextEditingController();
  late String selectedStatus;
  DateTime? startDate;
  DateTime? endDate;
  String? startDateString;
  String? endDateString;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.status;
    startDateString = (widget.startDate["day"] != -1)
        ? '${widget.startDate["day"]}/${widget.startDate["month"]}/${widget.startDate["year"]}'
        : 'Select Date';
    endDateString = (widget.endDate["day"] != -1)
        ? '${widget.endDate["day"]}/${widget.endDate["month"]}/${widget.endDate["year"]}'
        : 'Select Date';
  }

  @override
  void dispose() {
    chaptersController.dispose();
    scoreController.dispose();
    rewatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map listStatusToText = {
      "CURRENT": "Reading",
      "COMPLETED": "Completed",
      "PLANNING": "Planning",
      "DROPPED": "Dropped",
      "REPEATING": "Rereading",
      "NONE": "Select",
      "PAUSED": "Paused",
    };
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
      width: double.infinity,
      height: 470,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  GestureDetector(
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 250,
                          color: CupertinoColors.systemBackground,
                          child: CupertinoPicker(
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedStatus = [
                                  "CURRENT",
                                  "COMPLETED",
                                  "PLANNING",
                                  "DROPPED",
                                  "REPEATING",
                                  "PAUSED"
                                ][index];
                              });
                            },
                            children: [
                              Text("Reading"),
                              Text("Completed"),
                              Text("Planning"),
                              Text("Dropped"),
                              Text("Rereading"),
                              Text("Paused"),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.44,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(listStatusToText[selectedStatus] ?? "Select"),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Chapters Read",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: CupertinoTextField(
                      keyboardType: TextInputType.number,
                      controller: chaptersController,
                      placeholder: widget.progress.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Start Date",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  GestureDetector(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: 55,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          startDateString as String,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () async {
                      startDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      );
                      setState(() {
                        startDateString =
                            '${startDate!.day.toString()}/${startDate!.month.toString()}/${startDate!.year.toString()}';
                      });
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "End Date",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  GestureDetector(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: 55,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          endDateString as String,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () async {
                      endDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      );
                      setState(() {
                        endDateString =
                            '${endDate!.day.toString()}/${endDate!.month.toString()}/${endDate!.year.toString()}';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Score",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: CupertinoTextField(
                      keyboardType: TextInputType.number,
                      controller: scoreController,
                      placeholder: widget.score.toString(),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Total Rereads",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: CupertinoTextField(
                      controller: rewatchController,
                      keyboardType: TextInputType.number,
                      placeholder: widget.repeatCount.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      final response = await updateListItem(
                        widget.mediaId,
                        selectedStatus,
                        (chaptersController.value.text.isEmpty)
                            ? widget.progress
                            : int.parse(chaptersController.value.text),
                        (startDate == null)
                            ? widget.startDate
                            : {
                                "day": startDate!.day,
                                "month": startDate!.month,
                                "year": startDate!.year,
                              },
                        (endDate == null)
                            ? widget.endDate
                            : {
                                "day": endDate!.day,
                                "month": endDate!.month,
                                "year": endDate!.year,
                              },
                        (scoreController.value.text.isEmpty)
                            ? widget.score
                            : double.parse(scoreController.value.text),
                        (rewatchController.value.text.isEmpty)
                            ? widget.repeatCount
                            : int.parse(rewatchController.value.text),
                      );

                      if (response["data"] != null &&
                          response["data"]["SaveMediaListEntry"] != null) {
                        final newStatus =
                            response["data"]["SaveMediaListEntry"]["status"];
                        final newProgress =
                            response["data"]["SaveMediaListEntry"]["progress"];
                        final newMediaListData =
                            response["data"]["SaveMediaListEntry"];

                        widget.onUpdate(
                          newStatus,
                          newProgress,
                          newMediaListData,
                        );
                      }

                      Map newAlData = await getHomePageData();
                      Provider.of<StateProvider>(
                        context,
                        listen: false,
                      ).updateData(newAlData);

                      if (mounted) {
                        Navigator.of(context).pop();
                      }

                      setState(() {
                        isLoading = false;
                      });
                    },
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(),
                        ),
                        SizedBox(width: 8),
                        Text("Loading..."),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.check_mark),
                        SizedBox(width: 8),
                        Text("Save"),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
