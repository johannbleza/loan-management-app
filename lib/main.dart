import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/screens/agent_list.dart';
import 'package:loan_management/screens/balance_sheet_screen.dart';
import 'package:loan_management/screens/client_list.dart';
import 'package:loan_management/screens/monthly_report_screen.dart';
import 'package:loan_management/screens/overview_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  var sortedPayments = [];

  void setToOverdue() async {
    sortedPayments = await _databaseHelper.getAllPayments();
    final today = DateTime.now();

    for (var payment in sortedPayments) {
      DateTime dueDate = DateTime.parse(payment.dueDate);
      if (dueDate.isBefore(today) && payment.remarks == "Due") {
        await _databaseHelper.updatePaymentRemarks(
          payment.paymentId,
          "Overdue",
          "",
          "",
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    setToOverdue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 100, 102, 182),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // await _databaseHelper.deleteAllBalanceSheets();

            // await _databaseHelper.insertBalanceSheet(
            //   Balancesheet(
            //     date: 'Apr 5, 2025',
            //     balanceOUT: 100000,
            //     remarks: "Initial Balance",
            //     balanceIN: 0,
            //   ),
            // );
            // // await _databaseHelper.printAllBalanceSheets();

            // Get all balance sheets
            // List<Balancesheet> balanceSheets =
            //     await _databaseHelper.getAllBalanceSheets();
            // // // Print all balance sheets
            // for (var balanceSheet in balanceSheets) {
            //   print(
            //     "Date: ${balanceSheet.date}, OUT: ${balanceSheet.balanceOUT}, IN: ${balanceSheet.balanceIN}, Balance: ${balanceSheet.balanceAmount}, Remarks: ${balanceSheet.remarks}",
            //   );
            // }

            _databaseHelper.printAllBalanceSheets();

            // // print(
            // //   "Date: ${test.date}, OUT: ${test.balanceOUT}, IN: ${test.balanceIN}, Balance: ${test.balanceAmount}, Remarks: ${test.remarks}",
            // // );
          },
          child: const Icon(Icons.add),
        ),
        body: Row(
          children: [
            NavigationRail(
              minWidth: 100,
              leading: SizedBox(height: 100),
              backgroundColor: Colors.indigo,
              selectedIconTheme: const IconThemeData(color: Colors.indigo),
              unselectedIconTheme: const IconThemeData(color: Colors.white),
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white),
              elevation: 10,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Agents'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Clients'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month),
                  label: Text('Monthly\nReport', textAlign: TextAlign.center),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monetization_on_outlined),
                  label: Text('Balance \nSheet', textAlign: TextAlign.center),
                ),
              ],
            ),
            // Expanded content area
            Expanded(child: _buildScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return OverviewPage();
      case 1:
        return const AgentList();
      case 2:
        return const ClientList();
      case 3:
        return const MonthlyReport();
      case 4:
        return const BalanceSheetScreen();
      default:
        return const Center(child: Text('Select a navigation destination'));
    }
  }
}
