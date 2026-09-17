import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

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
    this.entryId,
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
  final int? entryId;
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
  int? startDay;
  int? startMonth;
  int? startYear;
  int? endDay;
  int? endMonth;
  int? endYear;
  bool isLoading = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.status;
    if (widget.startDate["day"] != null && widget.startDate["day"] != -1) {
      startDay = widget.startDate["day"] as int?;
      startMonth = widget.startDate["month"] as int?;
      startYear = widget.startDate["year"] as int?;
    }
    if (widget.endDate["day"] != null && widget.endDate["day"] != -1) {
      endDay = widget.endDate["day"] as int?;
      endMonth = widget.endDate["month"] as int?;
      endYear = widget.endDate["year"] as int?;
    }
  }

  @override
  void didUpdateWidget(covariant ListEditorBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate && startDate == null) {
      if (widget.startDate["day"] != null && widget.startDate["day"] != -1) {
        startDay = widget.startDate["day"] as int?;
        startMonth = widget.startDate["month"] as int?;
        startYear = widget.startDate["year"] as int?;
      }
    }
    if (oldWidget.endDate != widget.endDate && endDate == null) {
      if (widget.endDate["day"] != null && widget.endDate["day"] != -1) {
        endDay = widget.endDate["day"] as int?;
        endMonth = widget.endDate["month"] as int?;
        endYear = widget.endDate["year"] as int?;
      }
    }
  }

  String? _formatDate(BuildContext context, int? day, int? month, int? year) {
    if (day == null ||
        month == null ||
        year == null ||
        day == -1 ||
        month == -1 ||
        year == -1) {
      return null;
    }
    final isUS = Localizations.localeOf(context).countryCode == 'US';
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return isUS ? '$m/$d/$year' : '$d/$m/$year';
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
            "CURRENT": context.l10n.watching,
            "COMPLETED": context.l10n.completed,
            "PLANNING": context.l10n.planning,
            "DROPPED": context.l10n.dropped,
            "REPEATING": context.l10n.rewatching,
            "NONE": context.l10n.select,
            "PAUSED": context.l10n.paused,
          }
        : {
            "CURRENT": context.l10n.reading,
            "COMPLETED": context.l10n.completed,
            "PLANNING": context.l10n.planning,
            "DROPPED": context.l10n.dropped,
            "REPEATING": context.l10n.rereading,
            "NONE": context.l10n.select,
            "PAUSED": context.l10n.paused,
          };

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              context.l10n.status,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            LayoutBuilder(
                              builder: (context, c) => DropdownMenu(
                                width: c.maxWidth,
                                hintText: listStatusToText[widget.status],
                                dropdownMenuEntries: widget.isAnime
                                    ? [
                                        DropdownMenuEntry(
                                          value: "CURRENT",
                                          label: context.l10n.watching,
                                        ),
                                        DropdownMenuEntry(
                                          value: "COMPLETED",
                                          label: context.l10n.completed,
                                        ),
                                        DropdownMenuEntry(
                                          value: "PLANNING",
                                          label: context.l10n.planning,
                                        ),
                                        DropdownMenuEntry(
                                          value: "DROPPED",
                                          label: context.l10n.dropped,
                                        ),
                                        DropdownMenuEntry(
                                          value: "REPEATING",
                                          label: context.l10n.rewatching,
                                        ),
                                        DropdownMenuEntry(
                                          value: "PAUSED",
                                          label: context.l10n.paused,
                                        ),
                                      ]
                                    : [
                                        DropdownMenuEntry(
                                          value: "CURRENT",
                                          label: context.l10n.reading,
                                        ),
                                        DropdownMenuEntry(
                                          value: "COMPLETED",
                                          label: context.l10n.completed,
                                        ),
                                        DropdownMenuEntry(
                                          value: "PLANNING",
                                          label: context.l10n.planning,
                                        ),
                                        DropdownMenuEntry(
                                          value: "DROPPED",
                                          label: context.l10n.dropped,
                                        ),
                                        DropdownMenuEntry(
                                          value: "REPEATING",
                                          label: context.l10n.rereading,
                                        ),
                                        DropdownMenuEntry(
                                          value: "PAUSED",
                                          label: context.l10n.paused,
                                        ),
                                      ],
                                onSelected: (value) {
                                  selectedStatus = value as String;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              context.l10n.progress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            TextField(
                              keyboardType: TextInputType.number,
                              controller: chaptersController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: widget.progress.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              context.l10n.startDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 55,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDate(
                                          context,
                                          startDay,
                                          startMonth,
                                          startYear,
                                        ) ??
                                        context.l10n.selectDate,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final now = DateTime.now();
                                final initial =
                                    (startDay != null &&
                                        startMonth != null &&
                                        startYear != null)
                                    ? DateTime(
                                        startYear!,
                                        startMonth!,
                                        startDay!,
                                      )
                                    : now;
                                startDate = await showDatePicker(
                                  context: context,
                                  locale: Localizations.localeOf(context),
                                  initialDate: initial.isAfter(now)
                                      ? now
                                      : initial,
                                  firstDate: DateTime(1970),
                                  lastDate: now,
                                );
                                if (startDate != null) {
                                  setState(() {
                                    startDay = startDate!.day;
                                    startMonth = startDate!.month;
                                    startYear = startDate!.year;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              context.l10n.endDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 55,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDate(
                                          context,
                                          endDay,
                                          endMonth,
                                          endYear,
                                        ) ??
                                        context.l10n.selectDate,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final now = DateTime.now();
                                final initial =
                                    (endDay != null &&
                                        endMonth != null &&
                                        endYear != null)
                                    ? DateTime(endYear!, endMonth!, endDay!)
                                    : now;
                                endDate = await showDatePicker(
                                  context: context,
                                  locale: Localizations.localeOf(context),
                                  initialDate: initial.isAfter(now)
                                      ? now
                                      : initial,
                                  firstDate: DateTime(1970),
                                  lastDate: now,
                                );
                                if (endDate != null) {
                                  setState(() {
                                    endDay = endDate!.day;
                                    endMonth = endDate!.month;
                                    endYear = endDate!.year;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              context.l10n.scoreDesc,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            TextField(
                              keyboardType: TextInputType.number,
                              controller: scoreController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: widget.score.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              widget.isAnime
                                  ? context.l10n.totalRewatches
                                  : context.l10n.totalRereads,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            TextField(
                              controller: rewatchController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: widget.repeatCount.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (widget.entryId != null) ...[
                          ClipOval(
                            child: Material(
                              color: (isLoading || isDeleting)
                                  ? Colors.grey.shade400
                                  : Colors.red.shade600,
                              child: InkWell(
                                onTap: (isLoading || isDeleting)
                                    ? null
                                    : () async {
                                        setState(() {
                                          isDeleting = true;
                                        });

                                        final response = await deleteListItem(
                                          widget.entryId!,
                                        );

                                        if (response["data"] != null &&
                                            response["data"]["DeleteMediaListEntry"] !=
                                                null &&
                                            response["data"]["DeleteMediaListEntry"]["deleted"] ==
                                                true) {
                                          widget.onUpdate("NONE", 0, {});
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

                                        if (mounted) {
                                          setState(() {
                                            isDeleting = false;
                                          });
                                        }
                                      },
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: isDeleting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (isLoading || isDeleting)
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
                                          : int.parse(
                                              chaptersController.value.text,
                                            ),
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
                                          : double.parse(
                                              scoreController.value.text,
                                            ),
                                      (rewatchController.value.text.isEmpty)
                                          ? widget.repeatCount
                                          : int.parse(
                                              rewatchController.value.text,
                                            ),
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
                                ? Text(" ${context.l10n.loading}")
                                : Text(context.l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
