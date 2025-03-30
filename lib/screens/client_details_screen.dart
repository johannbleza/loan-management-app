import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
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

  void getClientById() async {
    var client = await _databaseHelper.getClientById(widget.clientId);

    setState(() {
      currentClient = client;
    });
  }

  void getPaymentsByClientId() async {
    var payment = await _databaseHelper.getPaymentsByClientId(widget.clientId);

    setState(() {
      payments = payment;
    });
  }

  @override
  void initState() {
    getClientById();
    getPaymentsByClientId();

    super.initState();
  }

  // Computed Vaues

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.black,
        elevation: 5,
        toolbarHeight: 64,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(
          "Client Profile",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // _databaseHelper.deleteAllPayments();
          // _databaseHelper.insertPayment(
          //   Payment(
          //     loanTerm: 1,
          //     dueDate: "2023-01-01",
          //     monthlyPayment: 4500.00,
          //     interestPaid: 2500.00,
          //     paymentDate: "2023-01-05",
          //     paymentMode: "Cash",
          //     clientId: widget.clientId,
          //   ),
          // );
          _databaseHelper.printAllPayments();
        },
      ),
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
                        SizedBox(height: 24),
                        Card(
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
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
                                          ).format(pattern: 'MMMM d, yyy')
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
                              color: Colors.indigo,

                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Text(
                                      "Remaining Balance:",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      "PHP 220,000.00",
                                      style: TextStyle(
                                        color: Colors.white,
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
                              color: Colors.indigo,

                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total Agent Share",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      "PHP 10,000.00",
                                      style: TextStyle(
                                        color: Colors.white,
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
                              color: Colors.indigoAccent,

                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Text(
                                      "Term Completed:",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      "5/12",
                                      style: TextStyle(
                                        color: Colors.white,
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
                              color: Colors.indigoAccent,

                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Text(
                                      "Next Due Date:",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      "April 11, 2025",
                                      style: TextStyle(
                                        color: Colors.white,
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
                          columnSpacing: 24,
                          columns: [
                            DataColumn(label: Text('Term')),
                            DataColumn(label: Text('Due Date')),
                            DataColumn(label: Text('Principal Balance')),
                            DataColumn(label: Text('Monthly Payment')),
                            DataColumn(label: Text('Interest Paid')),
                            DataColumn(label: Text('Capital Payment')),
                            DataColumn(label: Text('Agent Share')),
                            DataColumn(label: Text('Payment Date')),
                            DataColumn(label: Text('Mode of Payment')),
                            DataColumn(label: Text('Status')),
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
                                  DataCell(Text(payment.dueDate)),
                                  DataCell(
                                    Text(
                                      "PHP ${((currentClient.loanAmount) - (payments.indexOf(payment) * (currentClient.loanAmount / currentClient.loanTerm)).toDouble()).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${((currentClient.loanAmount + (currentClient.loanAmount * currentClient.interestRate / 100)) / currentClient.loanTerm).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      // Interest Paid
                                      "PHP ${(currentClient.loanAmount * (currentClient.interestRate / 100) / currentClient.loanTerm).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${(currentClient.loanAmount / currentClient.loanTerm).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "PHP ${(currentClient.loanAmount * (currentClient.interestRate / 100) * (currentClient.agentShare / 100) / currentClient.loanTerm).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                    ),
                                  ),
                                  DataCell(Text(payment.paymentDate ?? "")),
                                  DataCell(Text(payment.paymentMode ?? "")),
                                  DataCell(Text("Pending")),
                                ],
                              ),
                            DataRow(
                              cells: [
                                DataCell(Text("")),
                                DataCell(Text("")),
                                DataCell(Text("Total")),
                                DataCell(
                                  Text(
                                    "PHP ${(currentClient.loanAmount + (currentClient.loanAmount * (currentClient.interestRate / 100))).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP ${(currentClient.loanAmount * (currentClient.interestRate / 100)).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP ${currentClient.loanAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PHP ${(currentClient.loanAmount * (currentClient.interestRate / 100) * (currentClient.agentShare / 100)).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                  ),
                                ),
                                DataCell(Text("")),
                                DataCell(Text("")),
                                DataCell(Text("")),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 100),
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
