import 'package:flutter/material.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/agent.dart';
import 'package:loan_management/screens/agent_details_screen.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  var agentData = [];
  var clientCounts = [];

  void refreshAgentsTable() async {
    final agents = await _databaseHelper.getAllAgents();
    setState(() {
      agentData = agents;
    });
  }

  // Text Controllers
  final _agentNameTextController = TextEditingController();
  final _agentContactTextController = TextEditingController();
  final _agentEmailTextController = TextEditingController();

  void clearInputs() {
    _agentNameTextController.clear();
    _agentContactTextController.clear();
    _agentEmailTextController.clear();
  }

  @override
  void initState() {
    super.initState();
    refreshAgentsTable();
  }

  // Open Add Agent Dialog
  void showAddAgentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("New Agent"),
            actions: [
              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  clearInputs();
                },
                child: Text("Cancel"),
              ),
              // Add Button
              TextButton(
                onPressed: () {
                  if (_agentNameTextController.text.isNotEmpty) {
                    _databaseHelper.insertAgent(
                      Agent(
                        agentName: _agentNameTextController.text,
                        contactNo: _agentContactTextController.text,
                        email: _agentEmailTextController.text,
                      ),
                    );
                  }
                  Navigator.pop(context);
                  clearInputs();
                  // Refresh Table
                  refreshAgentsTable();
                },
                child: Text("Add"),
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _agentNameTextController,
                  decoration: const InputDecoration(
                    labelText: "Agent Name (Required)",
                  ),
                ),
                TextField(
                  controller: _agentContactTextController,
                  decoration: const InputDecoration(
                    labelText: "Phone No (Optional)",
                  ),
                ),
                TextField(
                  controller: _agentEmailTextController,
                  decoration: const InputDecoration(
                    labelText: "Email (Optional)",
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Confirm Delete Agent Dialog
  void confirmAgentDelete(Agent agent) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Agent"),
            content: Text(
              "Are you sure you want to delete Agent: ${agent.agentName}?",
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
                  _databaseHelper.deleteAgent(agent.agentId!);
                  refreshAgentsTable();
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              ),
            ],
          ),
    );
  }

  // Edit Agent Dialog
  void editAgentDialog(Agent agent) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Agent: ${agent.agentName}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Name"),
                  controller: _agentNameTextController,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Contact No (Optional)",
                  ),
                  controller: _agentContactTextController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Email (Optional)"),
                  controller: _agentEmailTextController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  clearInputs();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _databaseHelper.updateAgent(
                    Agent(
                      agentId: agent.agentId,
                      agentName: _agentNameTextController.text,
                      contactNo: _agentContactTextController.text,
                      email: _agentEmailTextController.text,
                    ),
                  );
                  refreshAgentsTable();
                  Navigator.pop(context);
                  clearInputs();
                },
                child: Text("Update"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Agent List", style: TextStyle(fontSize: 40)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 100,
                    columns: [
                      DataColumn(label: Text("")),
                      DataColumn(label: Text("Agent Name")),
                      DataColumn(label: Text("Contact No")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("No of Clients")),
                      DataColumn(
                        label: TextButton(
                          onPressed: () {
                            showAddAgentDialog();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.blue,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              Colors.white,
                            ),
                          ),
                          child: Text("Add New Agent +"),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      agentData.length,
                      (index) => DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AgentInfoScreen(
                                          agentId: agentData[index].agentId!,
                                        ),
                                  ),
                                );
                              },
                              child: Text(agentData[index].agentName ?? ""),
                            ),
                          ),
                          DataCell(Text(agentData[index].contactNo ?? "")),
                          DataCell(Text(agentData[index].email ?? "")),
                          DataCell(
                            FutureBuilder<int>(
                              future: _databaseHelper.getClientCountByAgentId(
                                agentData[index].agentId!,
                              ),
                              builder: (context, snapshot) {
                                return Text(snapshot.data?.toString() ?? '0');
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Edit Button
                                IconButton(
                                  onPressed: () {
                                    editAgentDialog(agentData[index]);
                                    _agentNameTextController.text =
                                        agentData[index].agentName;
                                    _agentContactTextController.text =
                                        agentData[index].contactNo;
                                    _agentEmailTextController.text =
                                        agentData[index].email;
                                  },
                                  icon: Icon(Icons.edit),
                                ),
                                // Delete Button
                                IconButton(
                                  onPressed: () {
                                    confirmAgentDelete(agentData[index]);
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
          ),
        ),
      ],
    );
  }
}
