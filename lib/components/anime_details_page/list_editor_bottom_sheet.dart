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
      "CURRENT": "Watching",
      "COMPLETED": "Completed",
      "PLANNING": "Planning",
      "DROPPED": "Dropped",
      "REPEATING": "Rewatching",
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
                      final statusList = ["CURRENT", "COMPLETED", "PLANNING", "DROPPED", "REPEATING", "PAUSED"];
                      final statusLabels = ["Watching", "Completed", "Planning", "Dropped", "Rewatching", "Paused"];
                      int initialIndex = statusList.indexOf(selectedStatus);
                      if (initialIndex == -1) initialIndex = 0;
                      
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 250,
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          child: Column(
                            children: [
                              Container(
                                height: 44,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CupertinoButton(
                                      child: Text('Done'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                                  itemExtent: 32,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      selectedStatus = statusList[index];
                                    });
                                  },
                                  children: statusLabels.map((label) => Center(child: Text(label))).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.44,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
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
                    "Episodes Watched",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: CupertinoTextField(
                      keyboardType: TextInputType.number,
                      controller: chaptersController,
                      placeholder: widget.progress.toString(),
                      padding: EdgeInsets.all(12),
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
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          startDateString as String,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 250,
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          child: Column(
                            children: [
                              Container(
                                height: 44,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CupertinoButton(
                                      child: Text('Done'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: DateTime.now(),
                                  minimumDate: DateTime(1970),
                                  maximumDate: DateTime.now(),
                                  onDateTimeChanged: (DateTime value) {
                                    startDate = value;
                                    setState(() {
                                      startDateString =
                                          '${value.day.toString()}/${value.month.toString()}/${value.year.toString()}';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          endDateString as String,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 250,
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          child: Column(
                            children: [
                              Container(
                                height: 44,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CupertinoButton(
                                      child: Text('Done'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: DateTime.now(),
                                  minimumDate: DateTime(1970),
                                  maximumDate: DateTime.now(),
                                  onDateTimeChanged: (DateTime value) {
                                    endDate = value;
                                    setState(() {
                                      endDateString =
                                          '${value.day.toString()}/${value.month.toString()}/${value.year.toString()}';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Total Rewatches",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: CupertinoTextField(
                      controller: rewatchController,
                      keyboardType: TextInputType.number,
                      placeholder: widget.repeatCount.toString(),
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              padding: EdgeInsets.symmetric(vertical: 12),
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
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(color: CupertinoColors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.check_mark, size: 20),
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
