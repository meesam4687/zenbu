import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/material.dart';
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
    required this.isAnime,
  });

  final String status;
  final int progress;
  final Map startDate;
  final Map endDate;
  final double score;
  final int repeatCount;
  final int mediaId;
  final Function(String, int, Map) onUpdate;
  final bool isAnime;

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
    Map listStatusToText = widget.isAnime
        ? {
            "CURRENT": "Watching",
            "COMPLETED": "Completed",
            "PLANNING": "Planning",
            "DROPPED": "Dropped",
            "REPEATING": "Rewatching",
            "NONE": "Select",
            "PAUSED": "Paused",
          }
        : {
            "CURRENT": "Reading",
            "COMPLETED": "Completed",
            "PLANNING": "Planning",
            "DROPPED": "Dropped",
            "REPEATING": "Rereading",
            "NONE": "Select",
            "PAUSED": "Paused",
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetWidth = constraints.maxWidth;
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(
              top: 40,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            width: double.infinity,
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
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        DropdownMenu(
                          width: sheetWidth * 0.44,
                          hintText: listStatusToText[widget.status],
                          dropdownMenuEntries: widget.isAnime
                              ? [
                                  const DropdownMenuEntry(
                                    value: "CURRENT",
                                    label: "Watching",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "COMPLETED",
                                    label: "Completed",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "PLANNING",
                                    label: "Planning",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "DROPPED",
                                    label: "Dropped",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "REPEATING",
                                    label: "Rewatching",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "PAUSED",
                                    label: "Paused",
                                  ),
                                ]
                              : [
                                  const DropdownMenuEntry(
                                    value: "CURRENT",
                                    label: "Reading",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "COMPLETED",
                                    label: "Completed",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "PLANNING",
                                    label: "Planning",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "DROPPED",
                                    label: "Dropped",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "REPEATING",
                                    label: "Rereading",
                                  ),
                                  const DropdownMenuEntry(
                                    value: "PAUSED",
                                    label: "Paused",
                                  ),
                                ],
                          onSelected: (value) {
                            selectedStatus = value as String;
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Text(
                          widget.isAnime ? "Episodes Watched" : "Chapters Read",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(
                          width: sheetWidth * 0.44,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: chaptersController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: widget.progress.toString(),
                            ),
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
                        const Text(
                          "Start Date",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: sheetWidth * 0.44,
                            height: 55,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                startDateString as String,
                                style: const TextStyle(fontSize: 16),
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
                            if (startDate != null) {
                              setState(() {
                                startDateString =
                                    '${startDate!.day.toString()}/${startDate!.month.toString()}/${startDate!.year.toString()}';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        const Text(
                          "End Date",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: sheetWidth * 0.44,
                            height: 55,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                endDateString as String,
                                style: const TextStyle(fontSize: 16),
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
                            if (endDate != null) {
                              setState(() {
                                endDateString =
                                    '${endDate!.day.toString()}/${endDate!.month.toString()}/${endDate!.year.toString()}';
                              });
                            }
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
                        const Text(
                          "Score",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(
                          width: sheetWidth * 0.44,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: scoreController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: widget.score.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Text(
                          widget.isAnime ? "Total Rewatches" : "Total Rereads",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(
                          width: sheetWidth * 0.44,
                          child: TextField(
                            controller: rewatchController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: widget.repeatCount.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
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
                                response["data"]["SaveMediaListEntry"] !=
                                    null) {
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
                            if (context.mounted) {
                              Provider.of<StateProvider>(
                                context,
                                listen: false,
                              ).updateData(newAlData);
                            }

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            setState(() {
                              isLoading = false;
                            });
                          },
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: isLoading
                        ? const Text(" Loading...")
                        : const Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
