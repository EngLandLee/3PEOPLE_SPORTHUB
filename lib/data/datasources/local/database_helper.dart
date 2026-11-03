import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/ticket_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sporthub_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              "ALTER TABLE tickets ADD COLUMN district TEXT DEFAULT 'Bình Thạnh'",
            );
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets (
        id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        venue_name TEXT NOT NULL,
        sport_type TEXT NOT NULL,
        court_number INTEGER NOT NULL,
        match_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_price REAL NOT NULL,
        qr_code_data TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        district TEXT DEFAULT 'Bình Thạnh'
      )
    ''');
  }

  Future<int> insertTicket(TicketModel ticket) async {
    final db = await instance.database;
    return await db.insert('tickets', ticket.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTicketStatus(String id, String status) async {
    final db = await instance.database;
    return await db.update(
      'tickets',
      {'status': status},
      where: 'id = ? OR booking_id = ?',
      whereArgs: [id, id],
    );
  }

  Future<int> deleteTicket(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tickets',
      where: 'id = ? OR booking_id = ?',
      whereArgs: [id, id],
    );
  }

  Future<List<TicketModel>> getTickets() async {
    final db = await instance.database;
    final maps = await db.query('tickets', orderBy: 'created_at DESC');
    return maps.map((e) => TicketModel.fromMap(e)).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
