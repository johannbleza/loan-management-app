import 'package:flutter/material.dart';
import 'package:loan_management/models/agent.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/client.dart';
import 'package:loan_management/screens/client_details_screen.dart';

class AgentDetailsScreen extends StatefulWidget {
  const AgentDetailsScreen({super.key, required this.agent});
  final Agent agent;

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  var clientsData = [];
  var agentsData = [];
  int? selectedAgentId;

  void getAllAgents() async {
    final agents = await _databaseHelper.getAllAgents();
    setState(() {
      agentsData = agents;
    });
  }

  void refreshClientsTable() async {
    final clients = await _databaseHelper.getClientsByAgentId(
      widget.agent.agentId!,
    );
    setState(() {
      clientsData = clients;
    });
  }

  // show Date
  DateTime? selectedDate;
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    setState(() {
      selectedDate = pickedDate;
      _loanDateTextController.text =
          selectedDate != null
              ? Jiffy.parseFromDateTime(
                selectedDate!,
              ).format(pattern: 'MMMM d, yyy')
              : '';
    });
  }

  // Text Controllers
  final _clientNameTextController = TextEditingController();
  final _loanAmountTextController = TextEditingController();
  final _loanTermTextController = TextEditingController();
  final _interestRateTextController = TextEditingController();
  final _agentShareTextController = TextEditingController();
  final _loanDateTextController = TextEditingController();

  @override
  void initState() {
    selectedAgentId = widget.agent.agentId;
    selectedDate = DateTime.now();
    _loanDateTextController.text = Jiffy.parseFromDateTime(
      selectedDate!,
    ).format(pattern: 'MMMM d, yyy');
    getAllAgents();
    refreshClientsTable();
    super.initState();
  }

  // Open Add Client Dialog
  void showAddClientDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("New Client"),
            actions: [
              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              // Add Button
              TextButton(
                onPressed: () async {
                  // Validate required fields
                  if (_clientNameTextController.text.isEmpty ||
                      _loanAmountTextController.text.isEmpty ||
                      _loanTermTextController.text.isEmpty ||
                      _interestRateTextController.text.isEmpty ||
                      _agentShareTextController.text.isEmpty ||
                      selectedDate == null ||
                      selectedAgentId == null) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Missing Information"),
                            content: Text(
                              "Please fill in all required fields.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              ),
                            ],
                          ),
                    );
                    return;
                  }

                  // Insert client
                  await _databaseHelper.insertClient(
                    Client(
                      clientName: _clientNameTextController.text,
                      loanDate: selectedDate.toString(),
                      loanAmount: double.parse(_loanAmountTextController.text),
                      loanTerm: int.parse(_loanTermTextController.text),
                      interestRate: double.parse(
                        _interestRateTextController.text,
                      ),
                      agentId: selectedAgentId!,
                      agentName:
                          agentsData
                              .firstWhere(
                                (agent) => agent.agentId == selectedAgentId!,
                              )
                              .agentName,
                      agentShare: double.parse(_agentShareTextController.text),
                    ),
                  );

                  Client? client = await _databaseHelper.getLastCreatedClient();
                  if (client != null) {
                    bool isGenerated = await _databaseHelper.hasPayments(
                      client.clientId!,
                    );
                    await _databaseHelper.insertBalanceSheet(
                      Balancesheet(
                        date: Jiffy.parse(selectedDate.toString()).yMMMd,
                        balanceOUT: double.parse(
                          _loanAmountTextController.text,
                        ),
                        balanceIN: 0,
                        clientId: client.clientId,
                        remarks: "Loan for ${_clientNameTextController.text}",
                      ),
                    );
                    if (!isGenerated) {
                      await _databaseHelper.generatePayments(client);
                    }

                    var allPayments = await _databaseHelper.getAllPayments();
                    final today = DateTime.now();
                    for (var payment in allPayments) {
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
                  }
                  // Clear form fields
                  _clientNameTextController.clear();
                  _loanAmountTextController.clear();
                  _loanTermTextController.clear();
                  _interestRateTextController.clear();
                  _agentShareTextController.clear();
                  _loanDateTextController.clear();
                  selectedDate = null;

                  Navigator.pop(context);
                  refreshClientsTable();
                },
                child: Text("Add"),
              ),
            ],
            content: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: "Client Name"),
                    controller: _clientNameTextController,
                  ),
                  TextField(
                    controller: _loanAmountTextController,
                    decoration: InputDecoration(labelText: "Loan Amount"),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  TextField(
                    controller: _loanTermTextController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Loan Term (months)",
                    ),
                  ),
                  TextField(
                    controller: _interestRateTextController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: "Interest Rate (%)"),
                  ),
                  SizedBox(height: 16),

                  // Add a state variable to track selected agent
                  DropdownMenu<int>(
                    initialSelection: widget.agent.agentId,
                    width: 300,
                    label: Text("Select Agent"),
                    onSelected: (int? value) {
                      setState(() {
                        selectedAgentId = value;
                      });
                    },
                    dropdownMenuEntries: List<DropdownMenuEntry<int>>.generate(
                      agentsData.length,
                      (index) => DropdownMenuEntry<int>(
                        value: agentsData[index].agentId,
                        label: agentsData[index].agentName,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _agentShareTextController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: "Agent Share(%)"),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Loan Date',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    controller: _loanDateTextController,
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(300, 0)),
                    ),
                    onPressed: () {
                      _selectDate();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("Select Loan Date"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Confirm Delete Client
  void confirmClientDelete(Client client) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Client"),
            content: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Are you sure you want to delete client: ${client.clientName}?",
              ),
            ),
            actions: [
              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _databaseHelper.deleteClient(client.clientId!);
                  refreshClientsTable();
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agent Details",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.indigo, width: 8),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Agent Name:"),
                                Text(
                                  widget.agent.agentName,
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
                    SizedBox(width: 40),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text("No of Clients:"),
                            Text(
                              clientsData.length.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Client List",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: [
                          DataColumn(label: Text("")),
                          DataColumn(label: Text("Client Name")),
                          DataColumn(label: Text("Amount")),
                          DataColumn(label: Text("Interest Rate")),
                          DataColumn(label: Text("Term")),
                          DataColumn(label: Text("Loan Date")),
                          DataColumn(label: Text("Agent Name")),
                          DataColumn(label: Text("Agent Share (%)")),
                          DataColumn(
                            label: TextButton(
                              onPressed: () {
                                showAddClientDialog();
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.blue,
                                ),
                                foregroundColor: WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                              ),
                              child: Text("Add New Client +"),
                            ),
                          ),
                        ],
                        rows: List<DataRow>.generate(
                          clientsData.length,
                          (index) => DataRow(
                            cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(
                                TextButton(
                                  onPressed: () async {
                                    bool isGenerated = await _databaseHelper
                                        .hasPayments(
                                          clientsData[index].clientId!,
                                        );
                                    if (!isGenerated) {
                                      await _databaseHelper.generatePayments(
                                        clientsData[index],
                                      );
                                    }
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
                                                  clientsData[index].clientId!,
                                              agentName:
                                                  agentsData
                                                      .firstWhere(
                                                        (agent) =>
                                                            agent.agentId ==
                                                            clientsData[index]
                                                                .agentId,
                                                      )
                                                      .agentName,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    clientsData[index].clientName ?? "",
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  "PHP ${clientsData[index].loanAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                ),
                              ),
                              DataCell(
                                Text(
                                  "${clientsData[index].interestRate.toString()}%",
                                ),
                              ),
                              DataCell(
                                Text(clientsData[index].loanTerm.toString()),
                              ),
                              DataCell(
                                Text(
                                  Jiffy.parse(
                                    clientsData[index].loanDate,
                                  ).format(pattern: 'MMMM d, yyy'),
                                ),
                              ),
                              DataCell(
                                Text(
                                  agentsData
                                      .firstWhere(
                                        (agent) =>
                                            agent.agentId ==
                                            clientsData[index].agentId,
                                      )
                                      .agentName,
                                ),
                              ),
                              DataCell(
                                Text("${clientsData[index].agentShare}%"),
                              ),
                              DataCell(
                                Center(
                                  child: IconButton(
                                    onPressed: () {
                                      confirmClientDelete(clientsData[index]);
                                    },
                                    icon: Icon(Icons.delete),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
