import 'package:flutter/material.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/screens/agent_list.dart';
import 'package:loan_management/screens/balance_sheet_screen.dart';
import 'package:loan_management/screens/client_list.dart';
import 'package:loan_management/screens/monthly_report_screen.dart';
import 'package:loan_management/screens/overview_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

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
        body: Row(
          children: [
            NavigationRail(
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
