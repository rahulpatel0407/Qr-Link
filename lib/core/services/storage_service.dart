import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Service for managing file storage and transfer history database.
class StorageService {
  Database? _db;

  /// Saves [data] to the app documents directory with the given [fileName].
  Future<String> saveFile(Uint8List data, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(data, flush: true);
    return filePath;
  }

  /// Gets the path to the app's downloads directory.
  Future<String> getDownloadsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'Downloads');
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// Deletes the file at [path].
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Initializes the SQLite database for transfer history.
  Future<Database> initDatabase() async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'qrlink_history.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE transfer_history (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            file_name TEXT,
            file_size INTEGER,
            compressed_size INTEGER,
            direction TEXT,
            timestamp TEXT,
            sha256 TEXT,
            file_path TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  /// Saves a transfer record to the database.
  Future<void> saveTransferRecord(Map<String, dynamic> sessionData, String filePath) async {
    final db = await initDatabase();
    await db.insert(
      'transfer_history',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'session_id': sessionData['session_id'],
        'file_name': sessionData['file_name'],
        'file_size': sessionData['file_size'],
        'compressed_size': sessionData['compressed_size'],
        'direction': sessionData['direction'],
        'timestamp': DateTime.now().toIso8601String(),
        'sha256': sessionData['sha256'],
        'file_path': filePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves the transfer history from the database.
  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    final db = await initDatabase();
    return await db.query('transfer_history', orderBy: 'timestamp DESC');
  }

  /// Deletes a transfer record by [id].
  Future<void> deleteTransferRecord(String id) async {
    final db = await initDatabase();
    await db.delete('transfer_history', where: 'id = ?', whereArgs: [id]);
  }

  /// Clears records older than [retentionDays].
  Future<void> clearOldRecords(int retentionDays) async {
    final db = await initDatabase();
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    await db.delete(
      'transfer_history',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
}
