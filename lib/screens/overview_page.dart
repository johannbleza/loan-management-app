import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/partialPayment.dart';
import 'package:loan_management/models/payment.dart';
import 'package:loan_management/screens/client_details_screen.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Payment> sortedPayments = [];
  List<Payment> currentMonthPayments = [];
  List<Payment> overduePayments = [];
  final paymentStatusController = TextEditingController();
  final paymentDateController = TextEditingController();
  final paymentModeController = TextEditingController();

  // Add properties to store totals
  double totalMonthlyPayment = 0.0;
  double totalInterestPaid = 0.0;
  double totalCapitalPayment = 0.0;

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

    // Current Month Payments
    for (var payment in sorted) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.month == today.month && dueDate.year == today.year) {
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

    // Calculate totals after getting payments
    calculateTotals(currentMonth);

    setState(() {
      sortedPayments = sorted;
      currentMonthPayments = currentMonth;
      overduePayments = overdue;
    });
  }

  // Method to calculate totals
  void calculateTotals(List<Payment> payments) {
    double interestTotal = 0.0;
    double capitalTotal = 0.0;

    // Count only payments that have been processed (paid or partial)
    for (var payment in payments) {
      if (payment.remarks == "Paid") {
        // Don't add monthly payment to totals
        interestTotal += payment.interestPaid;
        capitalTotal += payment.capitalPayment;
      } else if (payment.remarks == "Partial (Interest)") {
        interestTotal += payment.interestPaid;
      } else if (payment.remarks == "Partial (Principal)") {
        capitalTotal += payment.capitalPayment;
      }
    }

    // Set monthly total to 0 since we're not including it
    totalMonthlyPayment = 0.0;
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
    // Calculate total collections (sum of interest and capital payments only)
    double totalCollections = totalInterestPaid + totalCapitalPayment;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Text(
                    "Dashboard Overview",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Text("Total Collection Amount this Month "),
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
                      SizedBox(width: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Text("Total Overdue Payments Amount"),
                              SizedBox(height: 10),
                              Text(
                                "PHP ${overduePayments.fold<double>(0, (sum, payment) => sum + payment.monthlyPayment).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
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
                    "This Month's Collections (${currentMonthPayments.length.toString()}) - ${Jiffy.now().format(pattern: 'MMMM')} ",
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
                    rows: List<DataRow>.generate(
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
                          // Monthly Payment column
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].monthlyPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                            ),
                          ),
                          // Interest Amount with color based on status
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].interestPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: TextStyle(
                                color:
                                    (currentMonthPayments[index].remarks ==
                                                "Paid" ||
                                            currentMonthPayments[index]
                                                    .remarks ==
                                                "Partial (Interest)")
                                        ? Colors.green
                                        : Colors.black,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${currentMonthPayments[index].capitalPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: TextStyle(
                                color:
                                    (currentMonthPayments[index].remarks ==
                                                "Paid" ||
                                            currentMonthPayments[index]
                                                    .remarks ==
                                                "Partial (Principal)")
                                        ? Colors.green
                                        : Colors.black,
                              ),
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
                                                      "${paymentStatusController.text} - ${currentMonthPayments[index].clientName}",
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
                                                          .interestPaid +
                                                      currentMonthPayments[index]
                                                          .capitalPayment, // Sum of interest and capital only
                                                  balanceOUT: 0,
                                                  remarks:
                                                      "Full Payment - ${currentMonthPayments[index].clientName}",
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
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Overdue Payments (${overduePayments.length.toString()})",
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
                    rows: List<DataRow>.generate(
                      overduePayments.length,
                      (index) => DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(
                            Text(
                              Jiffy.parse(
                                overduePayments[index].dueDate,
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
                                              overduePayments[index].clientId,
                                          agentName:
                                              overduePayments[index].agentName,
                                        ),
                                  ),
                                ).whenComplete(() {
                                  getSortedPayments();
                                });
                              },
                              child: Text(overduePayments[index].clientName),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              color:
                                  overduePayments[index].remarks == "Paid"
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.transparent,
                              child: Text(
                                "PHP ${overduePayments[index].monthlyPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${overduePayments[index].interestPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: TextStyle(
                                color:
                                    (overduePayments[index].remarks == "Paid" ||
                                            overduePayments[index].remarks ==
                                                "Partial (Interest)")
                                        ? Colors.green
                                        : Colors.black,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "PHP ${overduePayments[index].capitalPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: TextStyle(
                                color:
                                    (overduePayments[index].remarks == "Paid" ||
                                            overduePayments[index].remarks ==
                                                "Partial (Principal)")
                                        ? Colors.green
                                        : Colors.black,
                              ),
                            ),
                          ),
                          DataCell(Text(overduePayments[index].agentName)),
                          DataCell(
                            Text(overduePayments[index].paymentDate ?? ""),
                          ),
                          DataCell(
                            Text(overduePayments[index].paymentMode ?? ""),
                          ),
                          DataCell(
                            TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (overduePayments[index].remarks ==
                                          "Due") {
                                        return Colors.orangeAccent;
                                      } else if (overduePayments[index]
                                              .remarks ==
                                          "Paid") {
                                        return Colors.green;
                                      } else if (overduePayments[index]
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
                                    overduePayments[index].paymentDate ?? "";
                                paymentModeController.text =
                                    overduePayments[index].paymentMode ?? "";
                                paymentStatusController.text =
                                    overduePayments[index].remarks ?? "";
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
                                                    overduePayments[index]
                                                        .paymentId!,
                                                  );
                                              if (overduePayments[index]
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
                                                    overduePayments[index]
                                                        .paymentId!,
                                                  );
                                              _databaseHelper
                                                  .insertPartialPayment(
                                                    Partialpayment(
                                                      dueDate:
                                                          overduePayments[index]
                                                              .dueDate,
                                                      interestRate:
                                                          overduePayments[index]
                                                              .interestRate,
                                                      capitalPayment:
                                                          overduePayments[index]
                                                              .capitalPayment,
                                                      interestPaid: 0,
                                                      remarks: "Unpaid",
                                                      agentShare:
                                                          overduePayments[index]
                                                              .agentShare,
                                                      agentId:
                                                          overduePayments[index]
                                                              .agentId,
                                                      agentName:
                                                          overduePayments[index]
                                                              .agentName,
                                                      clientId:
                                                          overduePayments[index]
                                                              .clientId,
                                                      clientName:
                                                          overduePayments[index]
                                                              .clientName,
                                                      paymentId:
                                                          overduePayments[index]
                                                              .paymentId!,
                                                    ),
                                                  );
                                            } else if (paymentStatusController
                                                    .text ==
                                                'Partial (Principal)') {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    overduePayments[index]
                                                        .paymentId!,
                                                  );
                                              _databaseHelper
                                                  .insertPartialPayment(
                                                    Partialpayment(
                                                      dueDate:
                                                          overduePayments[index]
                                                              .dueDate,
                                                      interestRate:
                                                          overduePayments[index]
                                                              .interestRate,
                                                      capitalPayment: 0,
                                                      interestPaid:
                                                          overduePayments[index]
                                                              .interestPaid,
                                                      remarks: "Unpaid",
                                                      agentShare:
                                                          overduePayments[index]
                                                              .agentShare,
                                                      agentId:
                                                          overduePayments[index]
                                                              .agentId,
                                                      agentName:
                                                          overduePayments[index]
                                                              .agentName,
                                                      clientId:
                                                          overduePayments[index]
                                                              .clientId,
                                                      clientName:
                                                          overduePayments[index]
                                                              .clientName,
                                                      paymentId:
                                                          overduePayments[index]
                                                              .paymentId!,
                                                    ),
                                                  );
                                            } else if (paymentStatusController
                                                    .text ==
                                                "Paid") {
                                              _databaseHelper
                                                  .deletePartialPaymentsByPaymentId(
                                                    overduePayments[index]
                                                        .paymentId!,
                                                  );
                                            }
                                            if (paymentStatusController.text !=
                                                "") {
                                              _databaseHelper
                                                  .updatePaymentRemarks(
                                                    overduePayments[index]
                                                        .paymentId!,
                                                    paymentStatusController
                                                        .text,
                                                    paymentDateController.text,
                                                    paymentModeController.text,
                                                  );
                                            }

                                            _databaseHelper
                                                .deleteBalanceSheetByPaymentId(
                                                  overduePayments[index]
                                                      .paymentId!,
                                                );

                                            if (paymentStatusController.text ==
                                                    "Partial (Interest)" ||
                                                paymentStatusController.text ==
                                                    "Partial (Principal)") {
                                              _databaseHelper.insertBalanceSheet(
                                                Balancesheet(
                                                  date:
                                                      paymentDateController
                                                          .text,
                                                  balanceIN:
                                                      paymentStatusController
                                                                  .text ==
                                                              "Partial (Interest)"
                                                          ? overduePayments[index]
                                                              .interestPaid
                                                          : overduePayments[index]
                                                              .capitalPayment,
                                                  balanceOUT: 0,
                                                  remarks:
                                                      "${paymentStatusController.text} - ${overduePayments[index].clientName}",
                                                  paymentId:
                                                      overduePayments[index]
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
                                                      overduePayments[index]
                                                          .interestPaid +
                                                      overduePayments[index]
                                                          .capitalPayment,
                                                  balanceOUT: 0,
                                                  remarks:
                                                      "Full Payment - ${overduePayments[index].clientName}",
                                                  clientId:
                                                      overduePayments[index]
                                                          .clientId,
                                                  paymentId:
                                                      overduePayments[index]
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
                              child: Text(overduePayments[index].remarks ?? ""),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
