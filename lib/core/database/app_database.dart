import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'dart:math';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();

  /// Test seam: reuse the production schema against an in-memory database.
  AppDatabase.forTesting(Database database) : _database = database;

  Database? _database;

  static const schema = <String>[
    '''
      CREATE TABLE gateways (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        name TEXT NOT NULL,
        scheme TEXT NOT NULL,
        base_url TEXT NOT NULL,
        api_token TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''',
    '''
      CREATE TABLE gateway_tombstones (
        sync_id TEXT PRIMARY KEY,
        deleted_at INTEGER NOT NULL
      )
    ''',
  ];

  static const _name = 'wol_client.db';

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    try {
      return await _openOnce();
    } catch (exception) {
      // The local database is a disposable cache: the cloud copy rebuilds it.
      // Only recover on web, and only for a damaged/stale schema.
      if (!kIsWeb || !_isDamaged(exception)) rethrow;
      await deleteDatabase(_name);
      return _openOnce();
    }
  }

  static bool _isDamaged(Object exception) {
    final message = exception.toString().toLowerCase();
    return message.contains('no such table') ||
        message.contains('no such column') ||
        message.contains('malformed') ||
        message.contains('not a database');
  }

  Future<Database> _openOnce() => openDatabase(
    _name,
    version: 2,
    onCreate: (db, _) async {
      for (final statement in schema) {
        await db.execute(statement);
      }
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE gateways ADD COLUMN sync_id TEXT');
        await db.execute('''
          CREATE TABLE gateway_tombstones (
            sync_id TEXT PRIMARY KEY,
            deleted_at INTEGER NOT NULL
          )
        ''');
        final rows = await db.query('gateways', columns: ['id']);
        final random = Random.secure();
        for (final row in rows) {
          await db.update(
            'gateways',
            {'sync_id': _newSyncId(random)},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await db.execute(
          'CREATE UNIQUE INDEX gateways_sync_id ON gateways(sync_id)',
        );
      }
    },
  );

  static String _newSyncId(Random random) =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${random.nextInt(0x7fffffff).toRadixString(36)}'
      '${random.nextInt(0x7fffffff).toRadixString(36)}';
}
