import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'models.dart';

/// Handles encrypted SQLite access and schema management.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  final _secureStorage = const FlutterSecureStorage();
  static const _keyName = 'beacon_db_key';
  Database? _database;

  bool get isOpen => _database != null;

  /// Opens the encrypted database, creating it if necessary.
  Future<void> open() async {
    if (_database != null) return;

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'beacon_encrypted.db');
    final passphrase = await _obtainOrCreatePassphrase();

    _database = await openDatabase(
      dbPath,
      password: passphrase,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedInitialData(db);
      },
    );
  }

  /// Closes the database so the file remains encrypted at rest.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<UserProfile?> fetchUserProfile() async {
    final db = _ensureDb();
    final rows = await db.query(BeaconTables.userProfile, limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = _ensureDb();
    await db.insert(
      BeaconTables.userProfile,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ConnectedDevice>> fetchConnectedDevices() async {
    final db = _ensureDb();
    final rows = await db.query(
      BeaconTables.connectedDevices,
      orderBy: 'last_seen DESC',
    );
    return rows.map(ConnectedDevice.fromMap).toList();
  }

  Future<void> upsertDevice(ConnectedDevice device) async {
    final db = _ensureDb();
    await db.insert(
      BeaconTables.connectedDevices,
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeDevice(String peerId) async {
    final db = _ensureDb();
    await db.delete(
      BeaconTables.connectedDevices,
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
  }

  Future<List<NetworkActivity>> fetchNetworkActivity({int limit = 50}) async {
    final db = _ensureDb();
    final rows = await db.query(
      BeaconTables.networkActivity,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(NetworkActivity.fromMap).toList();
  }

  Future<void> logActivity(NetworkActivity activity) async {
    final db = _ensureDb();
    await db.insert(BeaconTables.networkActivity, activity.toMap());
  }

  Database _ensureDb() {
    final db = _database;
    if (db == null) {
      throw StateError('Database not opened. Call open() first.');
    }
    return db;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${BeaconTables.userProfile} (
        id INTEGER PRIMARY KEY,
        name TEXT,
        role TEXT,
        phone TEXT,
        location TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ${BeaconTables.connectedDevices} (
        peer_id TEXT PRIMARY KEY,
        name TEXT,
        status TEXT,
        last_seen INTEGER,
        signal_strength INTEGER,
        is_emergency INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ${BeaconTables.networkActivity} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        peer_id TEXT,
        event TEXT,
        details TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    await db.insert(
      BeaconTables.userProfile,
      UserProfile(
        name: 'Field Operator',
        role: 'Civilian',
        phone: '+1 555 000 0000',
        location: 'Not set',
        updatedAt: now,
      ).toMap(),
    );

    // No mock devices - only real WiFi Direct discovered devices will be shown
  }

  Future<String> _obtainOrCreatePassphrase() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) return existing;

    final random = Random.secure();
    final codeUnits = List<int>.generate(32, (_) => random.nextInt(256));
    final passphrase = codeUnits
        .map((unit) => unit.toRadixString(16).padLeft(2, '0'))
        .join();
    await _secureStorage.write(key: _keyName, value: passphrase);
    return passphrase;
  }
}
