import 'package:flutter/material.dart';
import 'package:loan_management/database/database.dart';
import 'package:loan_management/screens/agents_screen.dart';
import 'package:loan_management/screens/clients_screen.dart';

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
              minWidth: 150,
              leading: SizedBox(height: 80),
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
        return const Center(child: Text('Loans Screen - Coming Soon'));
      case 1:
        return const AgentScreen();
      case 2:
        return const ClientsScreen();
      default:
        return const Center(child: Text('Select a navigation destination'));
    }
  }
}
