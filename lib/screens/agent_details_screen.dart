import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/client.dart';

class AgentInfoScreen extends StatefulWidget {
  const AgentInfoScreen({super.key, required this.agentId});

  final int agentId;

  @override
  State<AgentInfoScreen> createState() => _AgentInfoScreenState();
}

class _AgentInfoScreenState extends State<AgentInfoScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  dynamic currentAgent;

  void getAgentById(agentId) async {
    final agent = await _databaseHelper.getAgentById(agentId);
    setState(() {
      currentAgent = agent;
    });
  }

  var clientsData = [];
  var agentsData = [];
  int? selectedAgentId;

  void getAllAgents() async {
    final agents = await _databaseHelper.getAllAgents();
    setState(() {
      agentsData = agents;
    });
  }

  // Get All clients by agentID
  void refreshClientsTable() async {
    final clients = await _databaseHelper.getClientsByAgentId(widget.agentId);
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
    getAllAgents();
    getAgentById(widget.agentId);
    refreshClientsTable();
    super.initState();
  }

  // Open Add Client Dialog
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
                      agentShare: double.parse(_agentShareTextController.text),
                    ),
                  );

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
              width: 400,
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
                    width: 400,
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
                  SizedBox(height: 8),
                  OutlinedButton(
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

      body: Padding(
        padding: const EdgeInsets.only(left: 100),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Agent Details", style: TextStyle(fontSize: 40)),
                SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Agent Name:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.teal),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                      ),
                      child: Text(currentAgent?.agentName ?? ""),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "No of Clients:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.blueGrey,
                        ),
                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                      ),
                      child: Text(clientsData.length.toString()),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(" Client List", style: TextStyle(fontSize: 24)),
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
                          DataCell(Text(clientsData[index].clientName)),
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
                          DataCell(Text("${clientsData[index].agentShare}%")),
                          DataCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () {
                                    confirmClientDelete(clientsData[index]);
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
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
    );
  }
}
