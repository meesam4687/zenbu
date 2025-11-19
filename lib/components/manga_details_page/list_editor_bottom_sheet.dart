import 'package:al_client/anilist_connector.dart';
import 'package:al_client/state_provider.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.status;
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
                  DropdownMenu(
                    width: MediaQuery.of(context).size.width * 0.44,
                    hintText: listStatusToText[widget.status],
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: "CURRENT", label: "Reading"),
                      DropdownMenuEntry(value: "COMPLETED", label: "Completed"),
                      DropdownMenuEntry(value: "PLANNING", label: "Planning"),
                      DropdownMenuEntry(value: "DROPPED", label: "Dropped"),
                      DropdownMenuEntry(value: "REPEATING", label: "Rereading"),
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
                    "Chapters Read",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: chaptersController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hint: Text(widget.progress.toString()),
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
                  Text(
                    "Start Date",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: 55,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (widget.startDate["day"] != -1)
                              ? '${widget.startDate["day"]}/${widget.startDate["month"]}/${widget.startDate["year"]}'
                              : 'Select Date',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () {
                      showDatePicker(
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
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.44,
                      height: 55,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (widget.endDate["day"] != -1)
                              ? '${widget.endDate["day"]}/${widget.endDate["month"]}/${widget.endDate["year"]}'
                              : 'Select Date',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    onTap: () {
                      showDatePicker(
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
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: scoreController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hint: Text(widget.score.toString()),
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
                    "Total Rereads",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.44,
                    child: TextField(
                      controller: rewatchController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hint: Text(widget.repeatCount.toString()),
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
                        widget.startDate,
                        widget.endDate,
                        (scoreController.value.text.isEmpty)
                            ? widget.score
                            : double.parse(scoreController.value.text),
                        (rewatchController.value.text.isEmpty)
                            ? widget.progress
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
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.check),
              label: isLoading ? Text(" Loading...") : Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
