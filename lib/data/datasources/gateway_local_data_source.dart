import '../../core/database/app_database.dart';
import '../models/gateway.dart';

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
    final id = await (await _database.database).insert(
      'gateways',
      gateway.toMap(),
    );
    return Gateway.fromMap({...gateway.toMap(), 'id': id});
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

  Future<void> delete(int id) async => (await _database.database).delete(
    'gateways',
    where: 'id = ?',
    whereArgs: [id],
  );
}
