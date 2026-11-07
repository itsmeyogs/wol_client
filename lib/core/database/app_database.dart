import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await openDatabase(
    'wol_client.db',
    version: 1,
    onCreate: (db, _) => db.execute('''
          CREATE TABLE gateways (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            scheme TEXT NOT NULL,
            base_url TEXT NOT NULL,
            api_token TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        '''),
  );
}
