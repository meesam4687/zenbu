import 'package:flutter/material.dart';

class ListEditorBottomSheet extends StatelessWidget {
  const ListEditorBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController chaptersController = TextEditingController();
    final TextEditingController scoreController = TextEditingController();
    final TextEditingController rewatchController = TextEditingController();
    return Container(
      padding: EdgeInsets.only(top: 40, left: 20, right: 20),
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
                    hintText: "Reading",
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: "CURRENT", label: "Reading"),
                      DropdownMenuEntry(value: "COMPLETED", label: "Completed"),
                      DropdownMenuEntry(value: "PLANNING", label: "Planning"),
                      DropdownMenuEntry(value: "DROPPED", label: "Dropped"),
                      DropdownMenuEntry(value: "REPEATING", label: "Repeating"),
                    ],
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
                        hint: Text("56"),
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
                          '12/08/2025',
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
                          '28/08/2025',
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
                        hint: Text("10"),
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
                        hint: Text("0"),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
