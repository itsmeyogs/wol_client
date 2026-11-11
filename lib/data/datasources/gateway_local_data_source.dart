import '../../core/database/app_database.dart';
import '../models/gateway.dart';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

class GatewayLocalDataSource {
  GatewayLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;

  Future<List<Gateway>> getAll() async {
    final rows = await (await _database.database).query(
      'gateways',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Gateway.fromMap).toList();
  }

  Future<Gateway> insert(Gateway gateway) async {
    final value = gateway.syncId == null
        ? gateway.copyWith(syncId: _newSyncId())
        : gateway;
    final id = await (await _database.database).insert(
      'gateways',
      value.toMap(),
    );
    return Gateway.fromMap({...value.toMap(), 'id': id});
  }

  Future<Gateway> update(Gateway gateway) async {
    await (await _database.database).update(
      'gateways',
      gateway.toMap(),
      where: 'id = ?',
      whereArgs: [gateway.id],
    );
    return gateway;
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'gateways',
        columns: ['sync_id'],
        where: 'id = ?',
        whereArgs: [id],
      );
      final syncId = rows.isEmpty ? null : rows.single['sync_id'] as String?;
      if (syncId != null) {
        await txn.insert('gateway_tombstones', {
          'sync_id': syncId,
          'deleted_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.delete('gateways', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<String>> getTombstones() async =>
      (await (await _database.database).query(
        'gateway_tombstones',
        columns: ['sync_id'],
      )).map((row) => row['sync_id']! as String).toList();

  Future<void> removeTombstone(String syncId) async =>
      (await _database.database).delete(
        'gateway_tombstones',
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );

  Future<void> clearAll() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('gateway_tombstones');
      await txn.delete('gateways');
    });
  }

  Future<void> upsertFromSync(Gateway gateway) async {
    final db = await _database.database;
    final rows = await db.query(
      'gateways',
      columns: ['id'],
      where: 'sync_id = ?',
      whereArgs: [gateway.syncId],
    );
    if (rows.isEmpty) {
      await insert(gateway);
    } else {
      await db.update(
        'gateways',
        gateway.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [rows.single['id']],
      );
    }
  }

  Future<void> removeBySyncId(String syncId) async => (await _database.database)
      .delete('gateways', where: 'sync_id = ?', whereArgs: [syncId]);

  static String _newSyncId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${random.nextInt(0x7fffffff).toRadixString(36)}'
        '${random.nextInt(0x7fffffff).toRadixString(36)}';
  }
}
