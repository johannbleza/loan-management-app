import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/partialPayment.dart';
import 'package:loan_management/models/payment.dart';

class ClientDetailsScreen extends StatefulWidget {
  const ClientDetailsScreen({
    super.key,
    required this.clientId,
    required this.agentName,
  });
  final int clientId;
  final String agentName;

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  dynamic currentClient;
  dynamic currentAgent;
  List<Payment> payments = [];
  List<Partialpayment> partialPayment = [];
  double remainingBalance = 0.0;
  double agentShareCollected = 0.0;
  int termCompleted = 0;

  void getClientById() async {
    var client = await _databaseHelper.getClientById(widget.clientId);

    setState(() {
      currentClient = client;
    });
  }

  void getPaymentsByClientId() async {
    var payment = await _databaseHelper.getPaymentsByClientId(widget.clientId);
    var partialPayment = await _databaseHelper.getPartialPaymentsByClientId(
      widget.clientId,
    );

    setState(() {
      payments = payment;
      remainingBalance =
          currentClient.loanAmount * (1 + currentClient.interestRate / 100);
      termCompleted = 0;
      agentShareCollected = 0;
      for (var payment in payments) {
        if (payment.remarks == "Paid") {
          remainingBalance -= payment.monthlyPayment;
          agentShareCollected +=
              payment.monthlyPayment * payment.agentShare / 100;
          termCompleted++;
        } else if (payment.remarks == "Partial (Interest)") {
          agentShareCollected +=
              payment.interestPaid * payment.agentShare / 100;
          termCompleted++;
          remainingBalance -= payment.interestPaid;
        } else if (payment.remarks == "Partial (Principal)") {
          termCompleted++;
          agentShareCollected +=
              payment.capitalPayment * payment.agentShare / 100;
          remainingBalance -= payment.capitalPayment;
        }
      }
      this.partialPayment = partialPayment;
      for (var partial in partialPayment) {
        if (partial.remarks == "Paid") {
          termCompleted++;
          agentShareCollected +=
              (partial.interestPaid! + partial.capitalPayment!) *
              partial.agentShare /
              100;
          remainingBalance -= (partial.interestPaid! + partial.capitalPayment!);
        }
      }
    });
  }

  void updateRemainingBalance() {
    remainingBalance =
        currentClient.loanAmount * (1 + currentClient.interestRate / 100);
    for (var payment in payments) {
      if (payment.remarks == "Paid") {
        remainingBalance -= payment.monthlyPayment;
      } else if (payment.remarks == "Partial (Interest)") {
        remainingBalance -= payment.interestPaid;
      } else if (payment.remarks == "Partial (Principal)") {
        remainingBalance -= payment.capitalPayment;
      }
    }
    for (var partial in partialPayment) {
      if (partial.remarks == "Paid") {
        remainingBalance -= (partial.interestPaid! + partial.capitalPayment!);
      }
    }
  }

  // Text Controllers
  final paymentStatusController = TextEditingController();
  final paymentDateController = TextEditingController();
  final paymentModeController = TextEditingController();

  final partialStatusController = TextEditingController();
  final partialDateController = TextEditingController();
  final partialModeController = TextEditingController();

  void clearInputs() {
    paymentStatusController.clear();
    paymentDateController.clear();
    paymentModeController.clear();
  }

  @override
  void initState() {
    getClientById();
    getPaymentsByClientId();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(shadowColor: Colors.black, toolbarHeight: 64),
      body: ListView(
        children: [
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Client Details",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.indigoAccent,
                                width: 8,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Client Name:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currentClient != null
                                          ? currentClient.clientName
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Loan Start Date:",
                                      style: TextStyle(fontSize: 12),
                                    ),

                                    Text(
                                      currentClient != null
                                          ? Jiffy.parse(
                                            currentClient.loanDate,
                                          ).format(pattern: 'MMM d, yyy')
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Loan Amount:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currentClient != null
                                          ? "PHP ${currentClient.loanAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  children: [
                                    Text(
                                      "Loan Term:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currentClient != null
                                          ? currentClient.loanTerm.toString()
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  children: [
                                    Text(
                                      "Interest Rate:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currentClient != null
                                          ? "${currentClient.interestRate.toStringAsFixed(2)}%"
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Agent Name:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      widget.agentName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 40),
                                Column(
                                  children: [
                                    Text(
                                      "Agent Share:",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currentClient != null
                                          ? "${currentClient.agentShare.toStringAsFixed(2)}%"
                                          : "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text("Total Remaining Balance:"),
                                    Text(
                                      "PHP ${remainingBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text("Term Completed:"),
                                    Text(
                                      currentClient != null
                                          ? "$termCompleted/${currentClient.loanTerm + partialPayment.length}"
                                          : "",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text("Partial Payments:"),
                                    Text(
                                      partialPayment.length.toString(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text("Next Due Date:"),
                                    Text(
                                      payments.isNotEmpty &&
                                              payments.any(
                                                (payment) =>
                                                    payment.remarks == "Due" ||
                                                    payment.remarks ==
                                                        "Overdue",
                                              )
                                          ? Jiffy.parse(
                                            payments
                                                .firstWhere(
                                                  (payment) =>
                                                      payment.remarks ==
                                                          "Due" ||
                                                      payment.remarks ==
                                                          "Overdue",
                                                )
                                                .dueDate,
                                          ).format(pattern: 'MMM d, yyy')
                                          : "",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text("Agent Share Collected:"),
                                    Text(
                                      "PHP ${agentShareCollected.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Payment Schedule",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DataTable(
                          columnSpacing: 20,
                          columns: [
                            DataColumn(label: Text('Term')),
                            DataColumn(label: Text('Due Date')),
                            DataColumn(label: Text('Remaining Balance')),
                            DataColumn(label: Text('Monthly Payment')),
                            DataColumn(label: Text('Interest Amount')),
                            DataColumn(label: Text('Principal Amount')),
                            DataColumn(label: Text('Agent Share')),
                            DataColumn(label: Text('Payment Date')),
                            DataColumn(label: Text('Mode of Payment')),
                            DataColumn(label: Text('Remarks')),
                          ],
                          rows: [
                            // show all payments by clientId
                            for (var payment in payments)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      (payments.indexOf(payment) + 1)
                                          .toString(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Jiffy.parse(
                                        payment.dueDate,
                                      ).format(pattern: 'MMM d, yyy'),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${payment.principalBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${payment.monthlyPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${payment.interestPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      style: TextStyle(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${payment.capitalPayment.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      style: TextStyle(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      payment.remarks == "Partial (Interest)"
                                          ? "PHP ${(payment.interestPaid * payment.agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                          : payment.remarks ==
                                              "Partial (Principal)"
                                          ? "PHP ${(payment.capitalPayment * payment.agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                          : payment.remarks == "Paid"
                                          ? "PHP ${(payment.monthlyPayment * payment.agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                          : "",
                                    ),
                                  ),
                                  DataCell(Text(payment.paymentDate ?? "")),
                                  DataCell(Text(payment.paymentMode ?? "")),
                                  DataCell(
                                    TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >((Set<WidgetState> states) {
                                              if (payment.remarks == "Due") {
                                                return Colors.orangeAccent;
                                              } else if (payment.remarks ==
                                                  "Paid") {
                                                return Colors.green;
                                              } else if (payment.remarks ==
                                                  "Overdue") {
                                                return Colors.red;
                                              }
                                              return Colors.lightGreen;
                                            }),
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                              Colors.white,
                                            ),
                                      ),
                                      onPressed: () {
                                        paymentDateController.text =
                                            payment.paymentDate ?? "";
                                        paymentModeController.text =
                                            payment.paymentMode ?? "";
                                        paymentStatusController.text =
                                            payment.remarks ?? "";
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
                                                          label: "Due",
                                                          value: "Due",
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
                                                    if (paymentDateController
                                                        .text
                                                        .isEmpty) {
                                                      // show dialog to enter payment date
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
                                                    if (paymentStatusController
                                                            .text ==
                                                        'Due') {
                                                      _databaseHelper
                                                          .deletePartialPaymentsByPaymentId(
                                                            payment.paymentId!,
                                                          );
                                                      if (payment.remarks ==
                                                          "Overdue") {
                                                        paymentStatusController
                                                            .text = "Overdue";
                                                      }
                                                      paymentDateController
                                                          .text = "";
                                                      paymentModeController
                                                          .text = "";
                                                    } else if (paymentStatusController
                                                            .text ==
                                                        'Partial (Interest)') {
                                                      _databaseHelper
                                                          .deletePartialPaymentsByPaymentId(
                                                            payment.paymentId!,
                                                          );
                                                      _databaseHelper.insertPartialPayment(
                                                        Partialpayment(
                                                          dueDate:
                                                              payment.dueDate,
                                                          interestRate:
                                                              payment
                                                                  .interestRate,
                                                          capitalPayment:
                                                              payment
                                                                  .capitalPayment,
                                                          interestPaid: 0,
                                                          remarks: "Unpaid",
                                                          agentShare:
                                                              currentClient
                                                                  .agentShare,
                                                          agentId:
                                                              currentClient
                                                                  .agentId,
                                                          agentName:
                                                              currentClient
                                                                  .agentName,
                                                          clientId:
                                                              currentClient
                                                                  .clientId,
                                                          clientName:
                                                              currentClient
                                                                  .clientName,
                                                          paymentId:
                                                              payment
                                                                  .paymentId!,
                                                        ),
                                                      );
                                                    } else if (paymentStatusController
                                                            .text ==
                                                        'Partial (Principal)') {
                                                      _databaseHelper
                                                          .deletePartialPaymentsByPaymentId(
                                                            payment.paymentId!,
                                                          );
                                                      _databaseHelper.insertPartialPayment(
                                                        Partialpayment(
                                                          dueDate:
                                                              payment.dueDate,
                                                          interestRate:
                                                              payment
                                                                  .interestRate,
                                                          capitalPayment: 0,
                                                          interestPaid:
                                                              payment
                                                                  .interestPaid,
                                                          remarks: "Unpaid",
                                                          agentShare:
                                                              currentClient
                                                                  .agentShare,
                                                          agentId:
                                                              currentClient
                                                                  .agentId,
                                                          agentName:
                                                              currentClient
                                                                  .agentName,
                                                          clientId:
                                                              currentClient
                                                                  .clientId,
                                                          clientName:
                                                              currentClient
                                                                  .clientName,
                                                          paymentId:
                                                              payment
                                                                  .paymentId!,
                                                        ),
                                                      );
                                                    } else if (paymentStatusController
                                                            .text ==
                                                        "Paid") {
                                                      _databaseHelper
                                                          .deletePartialPaymentsByPaymentId(
                                                            payment.paymentId!,
                                                          );
                                                    }
                                                    _databaseHelper
                                                        .updatePaymentRemarks(
                                                          payment.paymentId!,
                                                          paymentStatusController
                                                              .text,
                                                          paymentDateController
                                                              .text,
                                                          paymentModeController
                                                              .text,
                                                        );

                                                    _databaseHelper
                                                        .deleteBalanceSheetByPaymentId(
                                                          payment.paymentId!,
                                                        );
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
                                                                  ? payment
                                                                      .interestPaid
                                                                  : paymentStatusController
                                                                          .text ==
                                                                      "Partial (Principal)"
                                                                  ? payment
                                                                      .capitalPayment
                                                                  : payment
                                                                      .monthlyPayment,
                                                          balanceOUT: 0,
                                                          remarks:
                                                              "Partial Payment for ${currentClient.clientName}",

                                                          clientId:
                                                              currentClient
                                                                  .clientId,
                                                          paymentId:
                                                              payment.paymentId,
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
                                                              payment
                                                                  .interestPaid! +
                                                              payment
                                                                  .capitalPayment!,
                                                          balanceOUT: 0,
                                                          remarks:
                                                              "Monthly Payment for ${currentClient.clientName}",
                                                          clientId:
                                                              currentClient
                                                                  .clientId,
                                                          paymentId:
                                                              payment.paymentId,
                                                        ),
                                                      );
                                                    }

                                                    getPaymentsByClientId();

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
                                      child: Text(payment.remarks ?? ""),
                                    ),
                                  ),
                                ],
                              ),
                            DataRow(
                              color: WidgetStateProperty.all(Colors.indigo),
                              cells: [
                                DataCell(Text("")),
                                DataCell(
                                  Text(
                                    "Total",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP 0.00",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (currentClient != null
                                        ? "PHP ${(currentClient.loanAmount + (currentClient.loanAmount * currentClient.interestRate / 100)).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                                        : " "),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP ${(currentClient != null ? (currentClient.loanAmount * currentClient.interestRate / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') : " ")}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP ${(currentClient != null ? currentClient.loanAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') : " ")}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(Text("")),
                                DataCell(Text("")),
                                DataCell(Text("")),
                                DataCell(Text("")),
                              ],
                            ),

                            // Partial Payments
                            if (partialPayment.isNotEmpty) ...[
                              DataRow(
                                cells: [
                                  DataCell(Text("")),
                                  DataCell(Text("")),
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
                              DataRow(
                                cells: [
                                  DataCell(Text("")),
                                  DataCell(
                                    Text(
                                      "Partial Payments",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(
                                    Text(
                                      "Interest",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "Principal",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "Agent Share",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "Payment Date",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "Mode of Payment",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "Remarks",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              for (var partial in partialPayment)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        (partialPayment.indexOf(partial) + 1)
                                            .toString(),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        Jiffy.parse(
                                          partial.dueDate,
                                        ).format(pattern: 'MMM d, yyy'),
                                        style: TextStyle(
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text("")),
                                    DataCell(Text("")),
                                    DataCell(
                                      Text(
                                        partial.interestPaid == 0
                                            ? ""
                                            : "PHP ${partial.interestPaid?.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                        style: TextStyle(
                                          color:
                                              partial.remarks == "Paid"
                                                  ? Colors.teal
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        partial.capitalPayment == 0
                                            ? ""
                                            : "PHP ${partial.capitalPayment?.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                        style: TextStyle(
                                          color:
                                              partial.remarks == "Paid"
                                                  ? Colors.teal
                                                  : Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                    (DataCell(
                                      Text(
                                        "PHP ${((partial.capitalPayment! + partial.interestPaid!) * partial.agentShare / 100).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      ),
                                    )),
                                    DataCell(Text(partial.paymentDate ?? "")),
                                    DataCell(Text(partial.paymentMode ?? "")),
                                    DataCell(
                                      TextButton(
                                        onPressed: () {
                                          // Handle partial payment status update dialog
                                          partialDateController.text =
                                              partial.paymentDate ?? "";
                                          partialModeController.text =
                                              partial.paymentMode ?? "";
                                          partialStatusController.text =
                                              partial.remarks ?? "";
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text("Update Status"),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            partialModeController,
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
                                                            partialDateController,
                                                        decoration: InputDecoration(
                                                          labelStyle: TextStyle(
                                                            color: Colors.black,
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
                                                              partialDateController
                                                                  .text = Jiffy.parse(
                                                                value
                                                                    .toString(),
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
                                                        hintText:
                                                            "Update Status",
                                                        initialSelection:
                                                            partialStatusController
                                                                .text,
                                                        dropdownMenuEntries: [
                                                          DropdownMenuEntry(
                                                            label: "Unpaid",
                                                            value: "Unpaid",
                                                          ),
                                                          DropdownMenuEntry(
                                                            label: "Paid",
                                                            value: "Paid",
                                                          ),
                                                        ],
                                                        onSelected: (value) {
                                                          setState(() {
                                                            partialStatusController
                                                                .text = value!;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        partialDateController
                                                            .clear();
                                                        partialModeController
                                                            .clear();
                                                        partialStatusController
                                                            .clear();
                                                      },
                                                      child: Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        // If No date is selected, show dialog
                                                        if (partialDateController
                                                            .text
                                                            .isEmpty) {
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

                                                        if (partialStatusController
                                                                .text ==
                                                            "Unpaid") {
                                                          partialDateController
                                                              .text = "";
                                                          partialModeController
                                                              .text = "";
                                                        }
                                                        _databaseHelper.updatePartialPayment(
                                                          partial
                                                              .partialPaymentId!,
                                                          partialStatusController
                                                              .text,
                                                          partialDateController
                                                              .text,
                                                          partialModeController
                                                              .text,
                                                        );

                                                        _databaseHelper
                                                            .deleteBalanceSheetByPartialPaymentId(
                                                              partial
                                                                  .partialPaymentId!,
                                                            );
                                                        if (partialStatusController
                                                                .text ==
                                                            "Paid") {
                                                          _databaseHelper.insertBalanceSheet(
                                                            Balancesheet(
                                                              date:
                                                                  partialDateController
                                                                      .text,
                                                              balanceIN:
                                                                  partial
                                                                      .capitalPayment! +
                                                                  partial
                                                                      .interestPaid!,
                                                              balanceOUT: 0,
                                                              remarks:
                                                                  "Partial Payment for ${currentClient.clientName}",

                                                              clientId:
                                                                  currentClient
                                                                      .clientId,
                                                              partialPaymentId:
                                                                  partial
                                                                      .partialPaymentId,
                                                            ),
                                                          );
                                                        }
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        partialDateController
                                                            .clear();
                                                        partialModeController
                                                            .clear();
                                                        partialStatusController
                                                            .clear();

                                                        getPaymentsByClientId();
                                                      },
                                                      child: Text("Save"),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.resolveWith<
                                                Color
                                              >((Set<WidgetState> states) {
                                                if (partial.remarks ==
                                                    "Unpaid") {
                                                  return Colors.redAccent;
                                                }
                                                return Colors.green;
                                              }),
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                Colors.white,
                                              ),
                                        ),
                                        child: Text(partial.remarks ?? ""),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
