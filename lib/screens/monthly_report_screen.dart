import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/partialPayment.dart';
import 'package:loan_management/models/payment.dart';
import 'package:loan_management/screens/client_details_screen.dart';

class MonthlyReport extends StatefulWidget {
  const MonthlyReport({super.key});

  @override
  State<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Payment> sortedPayments = [];
  List<Payment> currentMonthPayments = [];
  List<Payment> overduePayments = [];
  final paymentStatusController = TextEditingController();
  final paymentDateController = TextEditingController();
  final paymentModeController = TextEditingController();
  DateTime selectedMonth = DateTime.now(); // Added selected month variable

  // Add properties to store totals
  double totalMonthlyPayment = 0.0;
  double totalInterestPaid = 0.0;
  double totalCapitalPayment = 0.0;

  // Method to show month picker
  Future<void> _selectMonth(BuildContext context) async {
    // Show a custom month year picker
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month, 1);
        getSortedPayments();
      });
    }
  }

  // Custom month year picker function
  Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        DateTime? selectedDate = initialDate;

        return AlertDialog(
          title: Text('Select Month and Year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: CalendarDatePicker(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              currentDate: DateTime.now(),
              initialCalendarMode: DatePickerMode.year,
              onDateChanged: (DateTime date) {
                selectedDate = DateTime(date.year, date.month, 1);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void getSortedPayments() async {
    List<Payment> sorted = [];
    List<Payment> currentMonth = [];
    List<Payment> overdue = [];
    sorted = await _databaseHelper.getAllPayments();
    final today = DateTime.now();

    sorted.sort(
      (a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)),
    );

    for (var payment in sortedPayments) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.isBefore(today) && payment.remarks == "Due") {
        await _databaseHelper.updatePaymentRemarks(
          payment.paymentId!,
          "Overdue",
          "",
          "",
        );
      }
    }

    // Selected Month Payments (changed from Current Month)
    for (var payment in sorted) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.month == selectedMonth.month &&
          dueDate.year == selectedMonth.year) {
        currentMonth.add(payment);
      }
    }
    currentMonth.sort(
      (a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)),
    );

    // Get all Overdue Payments
    for (var payment in sorted) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.isBefore(today) && payment.remarks == "Overdue") {
        overdue.add(payment);
      }
    }

    // Calculate totals
    calculateTotals(currentMonth);

    setState(() {
      sortedPayments = sorted;
      currentMonthPayments = currentMonth;
      overduePayments = overdue;
    });
  }

  // Method to calculate totals to match transaction total styling
  void calculateTotals(List<Payment> payments) {
    double monthlyTotal = 0.0;
    double interestTotal = 0.0;
    double capitalTotal = 0.0;

    // Count only payments that have been processed (paid or partial)
    for (var payment in payments) {
      if (payment.remarks == "Paid") {
        monthlyTotal += payment.monthlyPayment;
        interestTotal += payment.interestPaid;
        capitalTotal += payment.capitalPayment;
      } else if (payment.remarks == "Partial (Interest)") {
        interestTotal += payment.interestPaid;
      } else if (payment.remarks == "Partial (Principal)") {
        capitalTotal += payment.capitalPayment;
      }
    }

    totalMonthlyPayment = monthlyTotal;
    totalInterestPaid = interestTotal;
    totalCapitalPayment = capitalTotal;
  }

  @override
  void initState() {
    getSortedPayments();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total collections (sum of all payments)
    double totalCollections =
        totalMonthlyPayment + totalInterestPaid + totalCapitalPayment;

    return ListView(
      children: [
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 64),
                Text(
                  "Monthly Report",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.indigo),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Date Today: ${Jiffy.parse(DateTime.now().toString()).format(pattern: "MMMM d, yyyy")}",
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () => _selectMonth(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Selected Month: ${Jiffy.parse(selectedMonth.toString()).format(pattern: "MMMM yyyy")}",
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Text(
                              "Totals Transactions for ${Jiffy.parse(selectedMonth.toString()).format(pattern: "MMMM yyyy")}",
                            ),
                            SizedBox(height: 10),
                            Text(
                              currentMonthPayments.length.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Text(
                              "Total Collections for ${Jiffy.parse(selectedMonth.toString()).format(pattern: "MMMM yyyy")}",
                            ),
                            SizedBox(height: 10),
                            Text(
                              "PHP ${totalCollections.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Text(
                  "${Jiffy.parse(selectedMonth.toString()).format(pattern: 'MMMM yyyy')} Collections",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 24),
                DataTable(
                  columnSpacing: 18,
                  columns: [
                    DataColumn(label: Text("")),
                    DataColumn(label: Text("Due Date")),
                    DataColumn(label: Text("Client Name")),
                    DataColumn(label: Text("Monthly Payment")),
                    DataColumn(label: Text("Interest Amount")),
                    DataColumn(label: Text("Principal Amount")),
                    DataColumn(label: Text("Agent Name")),
                    DataColumn(label: Text("Payment Date")),
                    DataColumn(label: Text("Mode of Payment")),
                    DataColumn(label: Text("Remarks")),
                  ],
                  rows: [
                    ...List<DataRow>.generate(
                      currentMonthPayments.length,
                      (index) => DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(
                            Text(
                              Jiffy.parse(
                                currentMonthPayments[index].dueDate,
                              ).format(pattern: "MMM d, yyyy"),
                            ),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: () async {
                                var allPayments =
                                    await _databaseHelper.getAllPayments();
                                final today = DateTime.now();
                                for (var payment in allPayments) {
                                  DateTime dueDate = DateTime.parse(
                                    payment.dueDate,
                                  );
                                  if (dueDate.isBefore(today) &&
                                      payment.remarks == "Due") {
                                    await _databaseHelper.updatePaymentRemarks(
                                      payment.paymentId!,
                                      "Overdue",
                                      "",
                                      "",
                                    );
                                  }
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ClientDetailsScreen(
                                          clientId:
                                              currentMonthPayments[index]
                                                  .clientId,
                                          agentName:
                                              currentMonthPayments[index]
                                                  .agentName,
                                        ),
                                  ),
                                ).whenComplete(() {
                                  getSortedPayments();
                                });
                              },
                              child: Text(
                                currentMonthPayments[index].clientName,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].monthlyPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].interestPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].capitalPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                            ),
                          ),
                          DataCell(Text(currentMonthPayments[index].agentName)),
                          DataCell(
                            Text(currentMonthPayments[index].paymentDate ?? ""),
                          ),
                          DataCell(
                            Text(currentMonthPayments[index].paymentMode ?? ""),
                          ),
                          DataCell(
                            TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (currentMonthPayments[index].remarks ==
                                          "Due") {
                                        return Colors.orangeAccent;
                                      } else if (currentMonthPayments[index]
                                              .remarks ==
                                          "Paid") {
                                        return Colors.green;
                                      } else if (currentMonthPayments[index]
                                              .remarks ==
                                          "Overdue") {
                                        return Colors.red;
                                      }
                                      return Colors.lightGreen;
                                    }),
                                foregroundColor: WidgetStateProperty.all(
                                  Colors.white,
                                ),
                              ),
                              onPressed: () {
                                paymentDateController.text =
                                    currentMonthPayments[index].paymentDate ??
                                    "";
                                paymentModeController.text =
                                    currentMonthPayments[index].paymentMode ??
                                    "";
                                paymentStatusController.text =
                                    currentMonthPayments[index].remarks ?? "";
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text("Update Status"),
                                      content: SizedBox(
                                        width: 250,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: paymentModeController,
                                              decoration: InputDecoration(
                                                labelText: "Mode of Payment",
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            TextField(
                                              enabled: false,
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                              controller: paymentDateController,
                                              decoration: InputDecoration(
                                                labelStyle: TextStyle(
                                                  color: Colors.black,
                                                ),
                                                labelText: "Payment Date",
                                                hintText: "Payment Date",
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            OutlinedButton(
                                              style: ButtonStyle(
                                                minimumSize:
                                                    WidgetStateProperty.all(
                                                      Size(250, 50),
                                                    ),
                                              ),
                                              onPressed: () {
                                                showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                ).then((value) {
                                                  if (value != null) {
                                                    paymentDateController
                                                        .text = Jiffy.parse(
                                                      value.toString(),
                                                    ).format(
                                                      pattern: 'MMM d, yyy',
                                                    );
                                                  }
                                                });
                                              },
                                              child: Text("Select Date"),
                                            ),
                                            SizedBox(height: 16),
                                            DropdownMenu(
                                              width: 250,
                                              hintText: "Update Status",
                                              initialSelection:
                                                  paymentStatusController.text,
                                              dropdownMenuEntries: [
                                                DropdownMenuEntry(
                                                  label: "Due",
                                                  value: "Due",
                                                ),
                                                DropdownMenuEntry(
                                                  label: "Partial (Interest)",
                                                  value: "Partial (Interest)",
                                                ),
                                                DropdownMenuEntry(
                                                  label: "Partial (Principal)",
                                                  value: "Partial (Principal)",
                                                ),
                                                DropdownMenuEntry(
                                                  label: "Paid",
                                                  value: "Paid",
                                                ),
                                              ],
                                              onSelected: (value) {
                                                setState(() {
                                                  paymentStatusController.text =
                                                      value!;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            paymentDateController.clear();
                                            paymentModeController.clear();
                                            paymentStatusController.clear();
                                          },
                                          child: Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Show dialog if there is no date selected
                                            if (paymentDateController.text ==
                                                "") {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text("Error"),
                                                    content: Text(
                                                      "Please select a payment date.",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        child: Text("OK"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              return;
                                            }
                                            if (paymentStatusController.text ==
                                                'Due') {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                  );

                                              if (currentMonthPayments[index]
                                                      .remarks ==
                                                  "Overdue") {
                                                paymentStatusController.text =
                                                    "Overdue";
                                              }
                                              paymentDateController.text = "";
                                              paymentModeController.text = "";
                                            } else if (paymentStatusController
                                                    .text ==
                                                'Partial (Interest)') {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                  );
                                              _databaseHelper.insertPartialPayment(
                                                Partialpayment(
                                                  dueDate:
                                                      currentMonthPayments[index]
                                                          .dueDate,
                                                  interestRate:
                                                      currentMonthPayments[index]
                                                          .interestRate,
                                                  capitalPayment:
                                                      currentMonthPayments[index]
                                                          .capitalPayment,
                                                  interestPaid: 0,
                                                  remarks: "Unpaid",
                                                  agentShare:
                                                      currentMonthPayments[index]
                                                          .agentShare,
                                                  agentId:
                                                      currentMonthPayments[index]
                                                          .agentId,
                                                  agentName:
                                                      currentMonthPayments[index]
                                                          .agentName,
                                                  clientId:
                                                      currentMonthPayments[index]
                                                          .clientId,
                                                  clientName:
                                                      currentMonthPayments[index]
                                                          .clientName,
                                                  paymentId:
                                                      currentMonthPayments[index]
                                                          .paymentId!,
                                                ),
                                              );
                                            } else if (paymentStatusController
                                                    .text ==
                                                'Partial (Principal)') {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                  );
                                              _databaseHelper.insertPartialPayment(
                                                Partialpayment(
                                                  dueDate:
                                                      currentMonthPayments[index]
                                                          .dueDate,
                                                  interestRate:
                                                      currentMonthPayments[index]
                                                          .interestRate,
                                                  capitalPayment: 0,
                                                  interestPaid:
                                                      currentMonthPayments[index]
                                                          .interestPaid,
                                                  remarks: "Unpaid",
                                                  agentShare:
                                                      currentMonthPayments[index]
                                                          .agentShare,
                                                  agentId:
                                                      currentMonthPayments[index]
                                                          .agentId,
                                                  agentName:
                                                      currentMonthPayments[index]
                                                          .agentName,
                                                  clientId:
                                                      currentMonthPayments[index]
                                                          .clientId,
                                                  clientName:
                                                      currentMonthPayments[index]
                                                          .clientName,
                                                  paymentId:
                                                      currentMonthPayments[index]
                                                          .paymentId!,
                                                ),
                                              );
                                            } else if (paymentStatusController
                                                    .text ==
                                                "Paid") {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                  );
                                            }
                                            if (paymentStatusController.text !=
                                                "") {
                                              _databaseHelper
                                                  .updatePaymentRemarks(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                    paymentStatusController
                                                        .text,
                                                    paymentDateController.text,
                                                    paymentModeController.text,
                                                  );
                                            }

                                            // Delete balanc sheet by paymentId
                                            _databaseHelper
                                                .deleteBalanceSheetByPaymentId(
                                                  currentMonthPayments[index]
                                                      .paymentId!,
                                                );

                                            if (paymentStatusController.text !=
                                                    "Due" ||
                                                paymentStatusController.text !=
                                                    "Overdue" ||
                                                paymentStatusController.text !=
                                                    "Paid") {
                                              _databaseHelper.insertBalanceSheet(
                                                Balancesheet(
                                                  date:
                                                      paymentDateController
                                                          .text,
                                                  balanceIN:
                                                      paymentStatusController
                                                                  .text ==
                                                              "Partial (Interest)"
                                                          ? currentMonthPayments[index]
                                                              .interestPaid
                                                          : paymentStatusController
                                                                  .text ==
                                                              "Partial (Principal)"
                                                          ? currentMonthPayments[index]
                                                              .capitalPayment
                                                          : currentMonthPayments[index]
                                                              .monthlyPayment,
                                                  balanceOUT: 0,
                                                  remarks:
                                                      "Partial Payment for ${currentMonthPayments[index].clientName}",
                                                  paymentId:
                                                      currentMonthPayments[index]
                                                          .paymentId,
                                                ),
                                              );
                                            } else if (paymentStatusController
                                                    .text ==
                                                "Paid") {
                                              _databaseHelper.insertBalanceSheet(
                                                Balancesheet(
                                                  date:
                                                      paymentDateController
                                                          .text,
                                                  balanceIN:
                                                      currentMonthPayments[index]
                                                          .monthlyPayment,
                                                  balanceOUT: 0,
                                                  remarks:
                                                      "Monthly Payment for ${currentMonthPayments[index].clientName}",
                                                  clientId:
                                                      currentMonthPayments[index]
                                                          .clientId,
                                                  paymentId:
                                                      currentMonthPayments[index]
                                                          .paymentId,
                                                ),
                                              );
                                            }

                                            getSortedPayments();
                                            Navigator.of(context).pop();
                                            paymentDateController.clear();
                                            paymentModeController.clear();
                                            paymentStatusController.clear();
                                          },
                                          child: Text("Save"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                currentMonthPayments[index].remarks ?? "",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
