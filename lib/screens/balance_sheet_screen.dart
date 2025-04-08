import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Balancesheet> _balanceSheetList = [];

  final dateTextController = TextEditingController();
  final outTextController = TextEditingController();
  final inTextController = TextEditingController();
  final remarksTextController = TextEditingController();

  void getBalanceSheet() async {
    List<Balancesheet> balanceSheetList =
        await _databaseHelper.getAllBalanceSheets();

    // if the list contains a date that is '' delete that entry
    balanceSheetList.removeWhere((element) => element.date == '');

    // sort the list by date in ascending order
    balanceSheetList.sort((a, b) {
      DateTime dateA = Jiffy.parse(a.date, pattern: 'MMM d, yyyy').dateTime;
      DateTime dateB = Jiffy.parse(b.date, pattern: 'MMM d, yyyy').dateTime;
      return dateA.compareTo(dateB);
    });

    setState(() {
      _balanceSheetList = balanceSheetList;
    });
  }

  @override
  void initState() {
    getBalanceSheet();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                Text(
                  "Balance Sheet",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('OUT')),
                      DataColumn(label: Text('IN')),
                      DataColumn(label: Text('Balance')),
                      DataColumn(
                        label: Text('Remarks'),
                        // Set fixed width for remarks column
                        tooltip: 'Remarks',
                      ),
                      DataColumn(
                        label: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                dateTextController.text = Jiffy.now().yMMMd;
                                inTextController.text = '0';
                                outTextController.text = '0';
                                return AlertDialog(
                                  title: Text("Add Entry"),
                                  content: SizedBox(
                                    width: 250,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        TextField(
                                          enabled: false,
                                          controller: dateTextController,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            labelStyle: TextStyle(
                                              color: Colors.black,
                                            ),
                                            labelText: "Enter Date",
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        OutlinedButton(
                                          style: ButtonStyle(
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                  Size(250, 50),
                                                ),
                                          ),
                                          onPressed: () {
                                            showDatePicker(
                                              context: context,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                              initialDate: DateTime.now(),
                                            ).then((value) {
                                              if (value != null) {
                                                dateTextController
                                                    .text = Jiffy.parse(
                                                  value.toString(),
                                                ).format(
                                                  pattern: "MMM d, yyyy",
                                                );
                                              }
                                            });
                                          },
                                          child: Text("Select Date"),
                                        ),
                                        SizedBox(height: 16),
                                        TextField(
                                          controller: outTextController,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            labelText: "Enter OUT Amount",
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d*$'),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        TextField(
                                          controller: inTextController,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            labelText: "Enter IN Amount",
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d*$'),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        TextField(
                                          controller: remarksTextController,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            labelText: "Remarks",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        dateTextController.clear();
                                        outTextController.clear();
                                        inTextController.clear();
                                        remarksTextController.clear();
                                      },
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (dateTextController.text.isEmpty ||
                                            outTextController.text.isEmpty ||
                                            inTextController.text.isEmpty) {
                                          Navigator.pop(context);
                                          return;
                                        }
                                        Balancesheet balanceSheet =
                                            Balancesheet(
                                              date: dateTextController.text,
                                              balanceOUT: double.parse(
                                                outTextController.text,
                                              ),
                                              balanceIN: double.parse(
                                                inTextController.text,
                                              ),
                                              balanceAmount:
                                                  double.parse(
                                                    inTextController.text,
                                                  ) -
                                                  double.parse(
                                                    outTextController.text,
                                                  ),
                                              remarks:
                                                  remarksTextController.text,
                                            );
                                        await _databaseHelper
                                            .insertBalanceSheet(balanceSheet);
                                        getBalanceSheet();
                                        Navigator.pop(context);
                                        dateTextController.clear();
                                        outTextController.clear();
                                        inTextController.clear();
                                        remarksTextController.clear();
                                      },
                                      child: Text("Add"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              Colors.blue,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.white,
                            ),
                          ),
                          child: Text('Add +'),
                        ),
                      ),
                    ],
                    rows: [
                      ..._balanceSheetList.map((balanceSheet) {
                        return DataRow(
                          cells: [
                            DataCell(Text(balanceSheet.date)),
                            DataCell(
                              Text(
                                'PHP ${balanceSheet.balanceOUT.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'PHP ${balanceSheet.balanceIN.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'PHP ${(balanceSheet.balanceIN - balanceSheet.balanceOUT).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 350, // Fixed width
                                child: Tooltip(
                                  message: balanceSheet.remarks ?? '',
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      balanceSheet.remarks ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      // show confirmation delete dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text("Delete Entry"),
                                            content: Text(
                                              "Are you sure you want to delete this entry?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _databaseHelper
                                                      .deleteBalanceSheet(
                                                        balanceSheet
                                                            .balanceSheetId!,
                                                      );
                                                  getBalanceSheet();
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Delete"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      DataRow(
                        color: MaterialStateProperty.all(Colors.indigo),
                        cells: [
                          DataCell(
                            Text(
                              'Total',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              'PHP ${_balanceSheetList.fold(0.0, (sum, item) => sum + item.balanceOUT).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              'PHP ${_balanceSheetList.fold(0.0, (sum, item) => sum + item.balanceIN).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              'PHP ${_balanceSheetList.fold(0.0, (sum, item) => sum + (item.balanceIN - item.balanceOUT)).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(Text('')), // Empty cell for Remarks column
                          DataCell(Text('')), // Empty cell for Actions column
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
