import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/partialPayment.dart';
import 'package:loan_management/models/payment.dart';
import 'package:loan_management/models/agent.dart'; // Add this import
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
  List<Agent> agents = []; // Add list to store agents
  int? selectedAgentId; // Add variable for selected agent
  final paymentStatusController = TextEditingController();
  final paymentDateController = TextEditingController();
  final paymentModeController = TextEditingController();
  DateTime selectedMonth = DateTime.now(); // Added selected month variable

  // Add properties to store totals
  double totalMonthlyPayment = 0.0;
  double totalInterestPaid = 0.0;
  double totalCapitalPayment = 0.0;
  double totalAgentShare = 0.0; // Added property for agent share total

  // Fetch all agents from database
  void getAllAgents() async {
    final agentList = await _databaseHelper.getAllAgents();
    setState(() {
      agents = agentList;
    });
  }

  // Method to show month picker
  Future<void> _selectMonth(BuildContext context) async {
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    int selectedMonthIndex = selectedMonth.month - 1; // 0-based index
    int selectedYearValue = selectedMonth.year;

    // Create a list of years from 2000 to current year + 5
    final List<int> years = List.generate(
      DateTime.now().year - 2000 + 6,
      (index) => 2000 + index,
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Month and Year'),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month dropdown
                DropdownMenu<int>(
                  width: 250,
                  label: Text("Month"),
                  initialSelection: selectedMonthIndex,
                  onSelected: (value) {
                    if (value != null) {
                      selectedMonthIndex = value;
                    }
                  },
                  dropdownMenuEntries: List.generate(
                    months.length,
                    (index) =>
                        DropdownMenuEntry(value: index, label: months[index]),
                  ),
                ),
                SizedBox(height: 16),
                // Year dropdown
                DropdownMenu<int>(
                  width: 250,
                  label: Text("Year"),
                  initialSelection: selectedYearValue,
                  onSelected: (value) {
                    if (value != null) {
                      selectedYearValue = value;
                    }
                  },
                  dropdownMenuEntries:
                      years
                          .map(
                            (year) => DropdownMenuEntry(
                              value: year,
                              label: year.toString(),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                    selectedYearValue,
                    selectedMonthIndex + 1,
                    1,
                  );
                  getSortedPayments();
                });
                Navigator.pop(context);
              },
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
        // Filter by agent if one is selected
        if (selectedAgentId != null) {
          if (payment.agentId == selectedAgentId) {
            currentMonth.add(payment);
          }
        } else {
          currentMonth.add(payment);
        }
      }
    }
    currentMonth.sort(
      (a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)),
    );

    // Get all Overdue Payments for the selected month and agent
    for (var payment in sorted) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.month == selectedMonth.month &&
          dueDate.year == selectedMonth.year &&
          dueDate.isBefore(today) &&
          payment.remarks == "Overdue") {
        // Filter by agent if one is selected
        if (selectedAgentId != null) {
          if (payment.agentId == selectedAgentId) {
            overdue.add(payment);
          }
        } else {
          overdue.add(payment);
        }
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
    double agentShareTotal = 0.0;

    // Count only payments that have been processed (paid or partial)
    for (var payment in payments) {
      if (payment.remarks == "Paid") {
        // Don't add monthly payment, only calculate interest and capital
        interestTotal += payment.interestPaid;
        capitalTotal += payment.capitalPayment;
        // Calculate agent share based on interest + capital
        agentShareTotal +=
            (payment.interestPaid + payment.capitalPayment) *
            payment.agentShare /
            100;
      } else if (payment.remarks == "Partial (Interest)") {
        interestTotal += payment.interestPaid;
        agentShareTotal += payment.interestPaid * payment.agentShare / 100;
      } else if (payment.remarks == "Partial (Principal)") {
        capitalTotal += payment.capitalPayment;
        agentShareTotal += payment.capitalPayment * payment.agentShare / 100;
      }
    }

    // Set monthly total to 0 since we're not including it
    totalMonthlyPayment = 0.0;
    totalInterestPaid = interestTotal;
    totalCapitalPayment = capitalTotal;
    totalAgentShare = agentShareTotal;
  }

  @override
  void initState() {
    getAllAgents();
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
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.indigo,
                          ),
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
                      SizedBox(width: 20),
                      // Add agent selection dropdown
                      DropdownMenu<int?>(
                        width: 250,
                        label: Text("Select Agent"),
                        initialSelection: selectedAgentId,
                        onSelected: (value) {
                          setState(() {
                            selectedAgentId = value;
                          });
                          // Refresh data with agent filter
                          getSortedPayments();
                        },
                        dropdownMenuEntries: [
                          DropdownMenuEntry(value: null, label: "All Agents"),
                          ...agents.map(
                            (agent) => DropdownMenuEntry(
                              value: agent.agentId,
                              label: agent.agentName,
                            ),
                          ),
                        ],
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
                      SizedBox(width: 20),
                      // Add card for Agent Share Total
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Text(
                                "Total Agent Share for ${Jiffy.parse(selectedMonth.toString()).format(pattern: "MMMM yyyy")}",
                              ),
                              SizedBox(height: 10),
                              Text(
                                "PHP ${totalAgentShare.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
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
                    "${Jiffy.parse(selectedMonth.toString()).format(pattern: 'MMMM yyyy')} Collections (${currentMonthPayments.length})",
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
                      DataColumn(
                        label: Text("Agent Share"),
                      ), // Added column for agent share
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
                                      await _databaseHelper
                                          .updatePaymentRemarks(
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
                            // Monthly Payment with color based on status
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
                            // Principal Amount with color based on status
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
                            DataCell(
                              Text(currentMonthPayments[index].agentName),
                            ),
                            // Add Agent Share cell
                            DataCell(
                              Text(
                                currentMonthPayments[index].remarks == "Paid"
                                    ? "PHP ${((currentMonthPayments[index].interestPaid + currentMonthPayments[index].capitalPayment) * currentMonthPayments[index].agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                    : currentMonthPayments[index].remarks ==
                                        "Partial (Interest)"
                                    ? "PHP ${(currentMonthPayments[index].interestPaid * currentMonthPayments[index].agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                    : currentMonthPayments[index].remarks ==
                                        "Partial (Principal)"
                                    ? "PHP ${(currentMonthPayments[index].capitalPayment * currentMonthPayments[index].agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                    : "PHP 0.00",
                              ),
                            ),
                            DataCell(
                              Text(
                                currentMonthPayments[index].paymentDate ?? "",
                              ),
                            ),
                            DataCell(
                              Text(
                                currentMonthPayments[index].paymentMode ?? "",
                              ),
                            ),
                            DataCell(
                              TextButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith<Color>((
                                        Set<WidgetState> states,
                                      ) {
                                        if (currentMonthPayments[index]
                                                .remarks ==
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
                                                controller:
                                                    paymentModeController,
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
                                                controller:
                                                    paymentDateController,
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
                                                    paymentStatusController
                                                        .text,
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
                                                    label:
                                                        "Partial (Principal)",
                                                    value:
                                                        "Partial (Principal)",
                                                  ),
                                                  DropdownMenuEntry(
                                                    label: "Paid",
                                                    value: "Paid",
                                                  ),
                                                ],
                                                onSelected: (value) {
                                                  setState(() {
                                                    paymentStatusController
                                                        .text = value!;
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
                                              if (paymentStatusController
                                                      .text ==
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
                                              if (paymentStatusController
                                                      .text !=
                                                  "") {
                                                _databaseHelper
                                                    .updatePaymentRemarks(
                                                      currentMonthPayments[index]
                                                          .paymentId!,
                                                      paymentStatusController
                                                          .text,
                                                      paymentDateController
                                                          .text,
                                                      paymentModeController
                                                          .text,
                                                    );
                                              }
                                              // Delete balanc sheet by paymentId
                                              _databaseHelper
                                                  .deleteBalanceSheetByPaymentId(
                                                    currentMonthPayments[index]
                                                        .paymentId!,
                                                  );
                                              // For regular payment entries
                                              if (paymentStatusController
                                                          .text !=
                                                      "Due" ||
                                                  paymentStatusController
                                                          .text !=
                                                      "Overdue" ||
                                                  paymentStatusController
                                                          .text !=
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
                                                        "${paymentStatusController.text} - ${currentMonthPayments[index].clientName} - Term ${index + 1}/${currentMonthPayments[index].loanTerm}",
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
                                                    // Use the sum of interest and capital payment
                                                    balanceIN:
                                                        currentMonthPayments[index]
                                                            .interestPaid +
                                                        currentMonthPayments[index]
                                                            .capitalPayment,
                                                    balanceOUT: 0,
                                                    remarks:
                                                        "Full Payment - ${currentMonthPayments[index].clientName} - Term ${index + 1}/${currentMonthPayments[index].loanTerm}",
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
                  // Add Overdue Payments Section
                  SizedBox(height: 40),
                  Text(
                    "Overdue Payments for ${Jiffy.parse(selectedMonth.toString()).format(pattern: "MMMM yyyy")}" +
                        (selectedAgentId != null
                            ? " (${agents.firstWhere((a) => a.agentId == selectedAgentId).agentName})"
                            : " (All Agents)"),
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
                      DataColumn(label: Text("Agent Share")),
                      DataColumn(label: Text("Payment Date")),
                      DataColumn(label: Text("Mode of Payment")),
                      DataColumn(label: Text("Remarks")),
                    ],
                    rows:
                        overduePayments.isEmpty
                            ? [
                              DataRow(
                                cells: [
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("No overdue payments")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                ],
                              ),
                            ]
                            : List<DataRow>.generate(
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
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ClientDetailsScreen(
                                                      clientId:
                                                          overduePayments[index]
                                                              .clientId,
                                                      agentName:
                                                          overduePayments[index]
                                                              .agentName,
                                                    ),
                                          ),
                                        ).whenComplete(() {
                                          getSortedPayments();
                                        });
                                      },
                                      child: Text(
                                        overduePayments[index].clientName,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${overduePayments[index].monthlyPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${overduePayments[index].interestPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${overduePayments[index].capitalPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(overduePayments[index].agentName),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${((overduePayments[index].interestPaid + overduePayments[index].capitalPayment) * overduePayments[index].agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      overduePayments[index].paymentDate ?? "",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      overduePayments[index].paymentMode ?? "",
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(Colors.red),
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                              Colors.white,
                                            ),
                                      ),
                                      onPressed: () {
                                        paymentStatusController.text =
                                            overduePayments[index].remarks ??
                                            "";
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          paymentModeController,
                                                      decoration: InputDecoration(
                                                        labelText:
                                                            "Mode of Payment",
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    TextField(
                                                      enabled: false,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                      controller:
                                                          paymentDateController,
                                                      decoration:
                                                          InputDecoration(
                                                            labelStyle:
                                                                TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                            labelText:
                                                                "Payment Date",
                                                            hintText:
                                                                "Payment Date",
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
                                                          initialDate:
                                                              DateTime.now(),
                                                          firstDate: DateTime(
                                                            2000,
                                                          ),
                                                          lastDate: DateTime(
                                                            2100,
                                                          ),
                                                        ).then((value) {
                                                          if (value != null) {
                                                            paymentDateController
                                                                .text = Jiffy.parse(
                                                              value.toString(),
                                                            ).format(
                                                              pattern:
                                                                  'MMM d, yyy',
                                                            );
                                                          }
                                                        });
                                                      },
                                                      child: Text(
                                                        "Select Date",
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),
                                                    DropdownMenu(
                                                      width: 250,
                                                      hintText: "Update Status",
                                                      initialSelection:
                                                          paymentStatusController
                                                              .text,
                                                      dropdownMenuEntries: [
                                                        DropdownMenuEntry(
                                                          label: "Overdue",
                                                          value: "Overdue",
                                                        ),
                                                        DropdownMenuEntry(
                                                          label:
                                                              "Partial (Interest)",
                                                          value:
                                                              "Partial (Interest)",
                                                        ),
                                                        DropdownMenuEntry(
                                                          label:
                                                              "Partial (Principal)",
                                                          value:
                                                              "Partial (Principal)",
                                                        ),
                                                        DropdownMenuEntry(
                                                          label: "Paid",
                                                          value: "Paid",
                                                        ),
                                                      ],
                                                      onSelected: (value) {
                                                        setState(() {
                                                          paymentStatusController
                                                              .text = value!;
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
                                                    paymentDateController
                                                        .clear();
                                                    paymentModeController
                                                        .clear();
                                                    paymentStatusController
                                                        .clear();
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    // Apply the same payment processing logic as in the monthly payments section
                                                    if (paymentDateController
                                                            .text ==
                                                        "") {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                              "Error",
                                                            ),
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
                                                                child: Text(
                                                                  "OK",
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                      return;
                                                    }

                                                    // Process the payment status update
                                                    if (paymentStatusController
                                                            .text ==
                                                        'Partial (Interest)') {
                                                      _databaseHelper
                                                          .deletePartialPaymentsByPaymentId(
                                                            overduePayments[index]
                                                                .paymentId!,
                                                          );
                                                      _databaseHelper.insertPartialPayment(
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
                                                      _databaseHelper.insertPartialPayment(
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

                                                    _databaseHelper
                                                        .updatePaymentRemarks(
                                                          overduePayments[index]
                                                              .paymentId!,
                                                          paymentStatusController
                                                              .text,
                                                          paymentDateController
                                                              .text,
                                                          paymentModeController
                                                              .text,
                                                        );

                                                    // Update the balance sheet
                                                    _databaseHelper
                                                        .deleteBalanceSheetByPaymentId(
                                                          overduePayments[index]
                                                              .paymentId!,
                                                        );

                                                    // For overdue payment entries
                                                    if (paymentStatusController
                                                                .text ==
                                                            "Partial (Interest)" ||
                                                        paymentStatusController
                                                                .text ==
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
                                                              "${paymentStatusController.text} - ${overduePayments[index].clientName} - Term ${index + 1}/${overduePayments[index].loanTerm}",
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
                                                          // Use the sum of interest and capital payment
                                                          balanceIN:
                                                              overduePayments[index]
                                                                  .interestPaid +
                                                              overduePayments[index]
                                                                  .capitalPayment,
                                                          balanceOUT: 0,
                                                          remarks:
                                                              "Full Payment - ${overduePayments[index].clientName} - Term ${index + 1}/${overduePayments[index].loanTerm}",
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
                                                    paymentDateController
                                                        .clear();
                                                    paymentModeController
                                                        .clear();
                                                    paymentStatusController
                                                        .clear();
                                                  },
                                                  child: Text("Save"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        overduePayments[index].remarks ?? "",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
