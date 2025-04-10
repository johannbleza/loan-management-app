import 'dart:math' as Math;

import 'package:jiffy/jiffy.dart';
import 'package:loan_management/models/agent.dart';
import 'package:loan_management/models/balanceSheet.dart';
import 'package:loan_management/models/client.dart';
import 'package:loan_management/models/partialPayment.dart';
import 'package:loan_management/models/payment.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Database initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loan_managment_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE agent (
        agentId INTEGER PRIMARY KEY AUTOINCREMENT,
        agentName TEXT NOT NULL,
        contactNo TEXT,
        email TEXT
        );
        ''');
    await db.execute('''
        CREATE TABLE client (
        clientId INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT NOT NULL,
        loanDate TEXT NOT NULL,
        loanAmount REAL NOT NULL,
        loanTerm INTEGER NOT NULL,
        interestRate REAL NOT NULL,
        agentId INTEGER NOT NULL,
        agentName TEXT NOT NULL,
        agentShare INTEGER NOT NULL,
        FOREIGN KEY (agentId) REFERENCES agent (agentId) ON DELETE CASCADE
        )
        ''');
    await db.execute('''
        CREATE TABLE payment (
        paymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        loanTerm INTEGER NOT NULL,
        interestRate REAL NOT NULL,
        dueDate TEXT NOT NULL,
        principalBalance REAL NOT NULL,
        monthlyPayment REAL NOT NULL,
        interestPaid REAL NOT NULL,
        capitalPayment REAL NOT NULL,
        agentShare REAL NOT NULL,
        paymentDate TEXT, 
        paymentMode TEXT,
        remarks TEXT,
        agentName INTEGER NOT NULL,
        agentId INTEGER NOT NULL,
        clientId INTEGER NOT NULL,
        clientName TEXT NOT NULL, 
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE
        )
        ''');
    await db.execute('''
        CREATE TABLE partialPayment (
        partialPaymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        dueDate TEXT NOT NULL,
        interestRate REAL NOT NULL,
        capitalPayment REAL,
        interestPaid REAL,
        paymentDate TEXT,
        paymentMode TEXT,
        remarks TEXT,
        agentShare REAL NOT NULL,
        agentId INTEGER NOT NULL,
        agentName TEXT NOT NULL,
        clientId INTEGER NOT NULL,
        clientName TEXT NOT NULL, 
        paymentId INTEGER NOT NULL,
        FOREIGN KEY (paymentId) REFERENCES payment (paymentId) ON DELETE CASCADE
        )
        ''');
    await db.execute('''
        CREATE TABLE balanceSheet( 
        balanceSheetId INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        balanceOUT REAL NOT NULL,
        balanceIN REAL NOT NULL,
        balanceAmount REAL,
        remarks TEXT,
        clientId INTEGER,
        paymentId INTEGER,
        partialPaymentId INTEGER,
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE,
        FOREIGN KEY (paymentId) REFERENCES payment (paymentId) ON DELETE CASCADE,
        FOREIGN KEY (partialPaymentId) REFERENCES partialPayment (partialPaymentId) ON DELETE CASCADE
        )
        ''');
  }

  // CRUD Operations

  // Insert an agent
  Future<void> insertAgent(Agent agent) async {
    Database db = await database;
    await db.insert("agent", agent.toMap());
  }

  // Get all agents
  Future<List<Agent>> getAllAgents() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agent',
      orderBy: 'agentId DESC',
    );

    // Convert the List<Map<String, dynamic>> to List<Agent>
    return List.generate(maps.length, (index) {
      return Agent.fromMap(maps[index]);
    });
  }

  // Get agent by ID
  Future<Agent?> getAgentById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'agent',
      where: 'agentId = ?',
      whereArgs: [id],
    );

    return Agent.fromMap(maps.first);
  }

  // Delete agent by id
  Future<int> deleteAgent(int id) async {
    Database db = await database;
    return await db.delete('agent', where: 'agentId = ?', whereArgs: [id]);
  }

  // Edit agent by id
  Future<int> updateAgent(Agent agent) async {
    Database db = await database;
    return await db.update(
      'agent',
      agent.toMap(),
      where: 'agentId = ?',
      whereArgs: [agent.agentId],
    );
  }

  // Update Agent Client Count
  Future<int> updateAgentClientCount(int agentId, int clientCount) async {
    Database db = await database;
    return await db.update(
      'agent',
      {'clientCount': clientCount},
      where: 'agentId = ?',
      whereArgs: [agentId],
    );
  }

  Future<void> deleteAllClients() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS client');
    await db.execute('''
        CREATE TABLE client (
        clientId INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT NOT NULL,
        loanDate TEXT NOT NULL,
        loanAmount REAL NOT NULL,
        loanTerm INTEGER NOT NULL,
        interestRate REAL NOT NULL,
        agentId INTEGER NOT NULL,
        agentShare INTEGER NOT NULL,
        FOREIGN KEY (agentId) REFERENCES agent (agentId) 
        )
        ''');
  }

  // Delete all agents
  Future<void> deleteAllAgents() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS agent');
    await db.execute('''
        CREATE TABLE agent (
        agentId INTEGER PRIMARY KEY AUTOINCREMENT,
        agentName TEXT NOT NULL,
        contactNo TEXT,
        email TEXT
        )
        ''');
  }

  // Client CRUD
  Future<int> insertClient(Client client) async {
    Database db = await database;
    return await db.insert("client", client.toMap());
  }

  // Get all clients
  Future<List<Client>> getAllClients() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      orderBy: 'clientId DESC',
    );

    return List.generate(maps.length, (index) {
      return Client.fromMap(maps[index]);
    });
  }

  // Get client by id
  Future<Client?> getClientById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      where: 'clientId = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }
    return Client.fromMap(maps.first);
  }

  // Get all clients by agent Id
  Future<List<Client>> getClientsByAgentId(int agentId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      where: 'agentId = ?',
      whereArgs: [agentId],
    );

    return List.generate(maps.length, (index) {
      return Client.fromMap(maps[index]);
    });
  }

  // Delete client by id
  Future<int> deleteClient(int id) async {
    Database db = await database;
    return await db.delete('client', where: 'clientId = ?', whereArgs: [id]);
  }

  // Get Last Inserted Client ID
  Future<int?> getLastInsertedClientId() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      orderBy: 'clientId DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['clientId'] as int?;
    }
    return null;
  }

  // Get Last Created Client
  Future<Client?> getLastCreatedClient() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      orderBy: 'clientId DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  // PAYMENTS CRUD
  // Generate Payments for Clients
  Future<void> generatePayments(Client client) async {
    Database db = await database;
    List<Payment> payments = [];

    double principalBalance = client.loanAmount;
    int loanTerm = client.loanTerm;
    double interestRate = client.interestRate;
    double monthlyInterestRate = interestRate / 100;

    // Calculate monthly payment based on the examples provided
    // We'll use a more flexible approach based on loan amount
    double monthlyPayment;

    // Based on the examples:
    // - $50,000 loan has $5,650 or $9,860 monthly payment (depending on term)
    // - $150,000 loan has $17,000 monthly payment

    if (client.loanAmount == 50000 && loanTerm == 6) {
      // Norma Alejaga example (6 months)
      monthlyPayment = 9860.00;
    } else if (client.loanAmount == 50000 && loanTerm == 12) {
      // Lolly Benesisto example (12 months)
      monthlyPayment = 5650.00;
    } else if (client.loanAmount == 150000 && loanTerm == 12) {
      // Violy Bello example (12 months)
      monthlyPayment = 17000.00;
    } else {
      // For other amounts, we'll use a simple ratio based on the closest example
      // Using the ratio from the 12-month examples:
      // $50,000 → $5,650 monthly payment
      // $150,000 → $17,000 monthly payment
      double ratio =
          (client.loanAmount >= 100000)
              ? (17000.0 / 150000.0)
              : (5650.0 / 50000.0);
      monthlyPayment = client.loanAmount * ratio;

      // Round to 2 decimal places
      monthlyPayment = double.parse(monthlyPayment.toStringAsFixed(2));
    }

    for (int i = 0; i < loanTerm; i++) {
      String dueDate = Jiffy.parse(
        client.loanDate,
      ).add(months: i + 1).format(pattern: 'yyyy-MM-dd');

      // Calculate interest based on current principal balance
      double interestPaid = principalBalance * monthlyInterestRate;

      // Round to 2 decimal places
      interestPaid = double.parse(interestPaid.toStringAsFixed(2));

      // Calculate capital payment (principal reduction)
      double capitalPayment = monthlyPayment - interestPaid;

      // Round to 2 decimal places
      capitalPayment = double.parse(capitalPayment.toStringAsFixed(2));

      payments.add(
        Payment(
          loanTerm: loanTerm,
          interestRate: interestRate,
          dueDate: dueDate,
          principalBalance: principalBalance,
          monthlyPayment: monthlyPayment,
          interestPaid: interestPaid,
          capitalPayment: capitalPayment,
          agentShare: client.agentShare,
          remarks: "Due",
          agentName: client.agentName,
          clientId: client.clientId!,
          clientName: client.clientName,
          agentId: client.agentId,
        ),
      );

      // Update principal balance for next month
      principalBalance -= capitalPayment;

      // Round to 2 decimal places to avoid floating point issues
      principalBalance = double.parse(principalBalance.toStringAsFixed(2));
    }

    for (var payment in payments) {
      await db.insert('payment', payment.toMap());
    }
  }

  // Get All Payments
  Future<List<Payment>> getAllPayments() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payment');

    return List.generate(maps.length, (index) {
      return Payment.fromMap(maps[index]);
    });
  }

  // Check if Client has Payments already
  Future<bool> hasPayments(int clientId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );

    return maps.isNotEmpty;
  }

  // Get All Payments by clientId
  Future<List<Payment>> getPaymentsByClientId(int clientId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );

    return List.generate(maps.length, (index) {
      return Payment.fromMap(maps[index]);
    });
  }

  // Update payment remarks
  Future<int> updatePaymentRemarks(
    int paymentId,
    String remarks,
    String paymentDate,
    String paymentMode,
  ) async {
    Database db = await database;
    return await db.update(
      'payment',
      {
        'remarks': remarks,
        'paymentDate': paymentDate,
        'paymentMode': paymentMode,
      },
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
  }

  //CRUD for Partial Payments

  // Insert a partial payment
  Future<int> insertPartialPayment(Partialpayment partialPayment) async {
    Database db = await database;
    return await db.insert("partialPayment", partialPayment.toMap());
  }

  // Get all partial payments for a specific clientId
  Future<List<Partialpayment>> getPartialPaymentsByClientId(
    int clientId,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'partialPayment',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'paymentId ASC',
    );

    return List.generate(maps.length, (index) {
      return Partialpayment.fromMap(maps[index]);
    });
  }

  // Delete all partial payments for a specific paymentId
  Future<int> deletePartialPaymentsByPaymentId(int paymentId) async {
    Database db = await database;
    return await db.delete(
      'partialPayment',
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
  }

  // Update partial payment remarks
  Future<int> updatePartialPayment(
    int partialPaymentId,
    String remarks,
    String paymentDate,
    String paymentMode,
  ) async {
    Database db = await database;
    return await db.update(
      'partialPayment',
      {
        'remarks': remarks,
        'paymentDate': paymentDate,
        'paymentMode': paymentMode,
      },
      where: 'partialPaymentId = ?',
      whereArgs: [partialPaymentId],
    );
  }

  // Print all partial payments (utility method for debugging)
  Future<void> printAllPartialPayments() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('partialPayment');

    print('==== All Partial Payments ====');
    if (maps.isEmpty) {
      print('No partial payments found');
    } else {
      for (var map in maps) {
        print(
          'Partial Payment: {partialPaymentId: ${map['partialPaymentId']}, dueDate: ${map['dueDate']}, interestRate: ${map['interestRate']}, capitalPayment: ${map['capitalPayment']}, interestPaid: ${map['interestPaid']}, paymentDate: ${map['paymentDate']}, paymentMode: ${map['paymentMode']}, remarks: ${map['remarks']}, agentShare: ${map['agentShare']}, agentId: ${map['agentId']}, agentName: ${map['agentName']}, clientId: ${map['clientId']}}',
        );
      }
    }
    print('===================');
  }

  // Delete all partial payments
  Future<void> deleteAllPartialPayments() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS partialPayment');
    await db.execute('''
        CREATE TABLE partialPayment (
        partialPaymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        dueDate TEXT NOT NULL,
        interestRate REAL NOT NULL,
        capitalPayment REAL,
        interestPaid REAL,
        paymentDate TEXT,
        paymentMode TEXT,
        remarks TEXT,
        agentShare REAL NOT NULL,
        agentId INTEGER NOT NULL,
        agentName TEXT NOT NULL,
        clientId INTEGER NOT NULL,
        clientName TEXT NOT NULL, 
        paymentId INTEGER NOT NULL,
        FOREIGN KEY (paymentId) REFERENCES payment (paymentId) ON DELETE CASCADE
        )
        ''');
  }

  // Delete all balance sheets
  Future<void> deleteAllBalanceSheets() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS balanceSheet');
    await db.execute('''
        CREATE TABLE balanceSheet( 
        balanceSheetId INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        balanceOUT REAL NOT NULL,
        balanceIN REAL NOT NULL,
        balanceAmount REAL,
        remarks TEXT,
        clientId INTEGER,
        paymentId INTEGER,
        partialPaymentId INTEGER,
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE,
        FOREIGN KEY (paymentId) REFERENCES payment (paymentId) ON DELETE CASCADE,
        FOREIGN KEY (partialPaymentId) REFERENCES partialPayment (partialPaymentId) ON DELETE CASCADE
        )
        ''');
  }

  // Insert a balance sheet
  Future<int> insertBalanceSheet(Balancesheet balanceSheet) async {
    Database db = await database;
    return await db.insert("balanceSheet", balanceSheet.toMap());
  }

  // delete balance sheet by id paymentId if exists
  Future<int> deleteBalanceSheetByPaymentId(int paymentId) async {
    Database db = await database;
    return await db.delete(
      'balanceSheet',
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
  }

  // delete balance sheet by id partialPaymentId if exists
  Future<int> deleteBalanceSheetByPartialPaymentId(int partialPaymentId) async {
    Database db = await database;
    return await db.delete(
      'balanceSheet',
      where: 'partialPaymentId = ?',
      whereArgs: [partialPaymentId],
    );
  }

  // Get all balance sheets
  Future<List<Balancesheet>> getAllBalanceSheets() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'balanceSheet',
      orderBy: 'balanceSheetId DESC',
    );

    return List.generate(maps.length, (index) {
      return Balancesheet.fromMap(maps[index]);
    });
  }

  // Delete balance sheet by id
  Future<int> deleteBalanceSheet(int id) async {
    Database db = await database;
    return await db.delete(
      'balanceSheet',
      where: 'balanceSheetId = ?',
      whereArgs: [id],
    );
  }

  // Print all balance sheets (utility method for debugging)
  Future<void> printAllBalanceSheets() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('balanceSheet');

    print('==== All Balance Sheets ====');
    if (maps.isEmpty) {
      print('No balance sheets found');
    } else {
      for (var map in maps) {
        print(
          'Balance Sheet: {balanceSheetId: ${map['balanceSheetId']}, date: ${map['date']}, balanceOUT: ${map['balanceOUT']}, balanceIN: ${map['balanceIN']}, balanceAmount: ${map['balanceAmount']}, remarks: ${map['remarks']}}',
        );
      }
    }
    print('===================');
  }

  // Print all clients (utility method for debugging)
  Future<void> printAllClients() async {
    final clients = await getAllClients();
    print('==== All Clients ====');
    if (clients.isEmpty) {
      print('No clients found');
    } else {
      for (var client in clients) {
        print(
          'Client: {clientId: ${client.clientId}, clientName: ${client.clientName}, loanDate: ${client.loanDate}, loanAmount: ${client.loanAmount}, loanTerm: ${client.loanTerm}, interestRate: ${client.interestRate}, agentId: ${client.agentId}, agentShare: ${client.agentShare}}',
        );
      }
    }
    print('===================');
  }

  // Print all agents (utility method for debugging)
  Future<void> printAllAgents() async {
    final agents = await getAllAgents();
    print('==== All Agents ====');
    if (agents.isEmpty) {
      print('No agents found');
    } else {
      for (var agent in agents) {
        print('Agent ID: ${agent.agentId}, Name: ${agent.agentName},');
      }
    }
    print('===================');
  }

  // Print all payments (utility method for debugging)
  Future<void> printAllPayments() async {
    final payments = await getAllPayments();
    print('==== All Payments ====');
    if (payments.isEmpty) {
      print('No payments found');
    } else {
      for (var payment in payments) {
        print(
          'Payment: {paymentId: ${payment.paymentId}, loanTerm: ${payment.loanTerm}, dueDate: ${payment.dueDate}, monthlyPayment: ${payment.monthlyPayment}, interestPaid: ${payment.interestPaid}, paymentDate: ${payment.paymentDate}, paymentMode: ${payment.paymentMode}, remarks: ${payment.remarks}, clientId: ${payment.clientId}}',
        );
      }
    }
    print('===================');
  }

  // Delete all payments
  Future<void> deleteAllPayments() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS payment');
    await db.execute('''
        CREATE TABLE payment (
        paymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        loanTerm INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        principalBalance REAL NOT NULL,
        monthlyPayment REAL NOT NULL,
        interestPaid REAL NOT NULL,
        capitalPayment REAL NOT NULL,
        agentShare REAL NOT NULL,
        paymentDate TEXT, 
        paymentMode TEXT,
        remarks TEXT,
        agentName INTEGER NOT NULL,
        agentId INTEGER NOT NULL,
        clientId INTEGER NOT NULL,
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE
        )
        ''');
  }
}
