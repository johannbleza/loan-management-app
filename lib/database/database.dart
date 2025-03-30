import 'package:jiffy/jiffy.dart';
import 'package:loan_management/models/agent.dart';
import 'package:loan_management/models/client.dart';
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
        )
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
        agentShare INTEGER NOT NULL,
        FOREIGN KEY (agentId) REFERENCES agent (agentId) ON DELETE CASCADE
        )
        ''');
    await db.execute('''
        CREATE TABLE payment (
        paymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        loanTerm INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        monthlyPayment REAL NOT NULL,
        interestPaid REAL NOT NULL,
        paymentDate TEXT, 
        paymentMode TEXT,
        remarks TEXT,
        clientId INTEGER NOT NULL,
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE
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
    final List<Map<String, dynamic>> maps = await db.query('agent');

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

  // Get number of clients per agentID
  Future<int> getClientCountByAgentId(int agentId) async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM client WHERE agentId = ?',
      [agentId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
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
    final List<Map<String, dynamic>> maps = await db.query('client');

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

  // PAYMENTS CRUD
  // generate Payments for a client
  Future<void> generatePayments(Client client) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment',
      where: 'clientId = ?',
      whereArgs: [client.clientId],
    );

    if (maps.isNotEmpty) {
      return;
    }

    double totalLoanAmount =
        client.loanAmount + (client.loanAmount * (client.interestRate / 100));
    double monthlyPayment = totalLoanAmount / client.loanTerm;

    for (int i = 0; i < client.loanTerm; i++) {
      final payment = Payment(
        loanTerm: client.loanTerm,
        dueDate: Jiffy.parse(
          client.loanDate,
        ).add(months: i + 1).format(pattern: 'MMMM d, yyy'),
        monthlyPayment: monthlyPayment,
        interestPaid:
            totalLoanAmount * (client.interestRate / 100) / client.loanTerm,
        paymentDate: null,
        paymentMode: null,
        remarks: null,
        clientId: client.clientId!,
      );
      await db.insert("payment", payment.toMap());
    }
  }

  Future<void> insertPayment(Payment payment) async {
    Database db = await database;
    await db.insert("payment", payment.toMap());
  }

  // Get All Payments
  Future<List<Payment>> getAllPayments() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payment');

    return List.generate(maps.length, (index) {
      return Payment.fromMap(maps[index]);
    });
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
        print('Agent ID: ${agent.agentId}, Name: ${agent.agentName}');
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
        monthlyPayment REAL NOT NULL,
        interestPaid REAL NOT NULL,
        paymentDate TEXT, 
        paymentMode TEXT,
        remarks TEXT,
        clientId INTEGER NOT NULL,
        FOREIGN KEY (clientId) REFERENCES client (clientId) ON DELETE CASCADE
        )
        ''');
  }
}
