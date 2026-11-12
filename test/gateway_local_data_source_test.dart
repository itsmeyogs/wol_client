import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wol_client/core/database/app_database.dart';
import 'package:wol_client/data/datasources/gateway_local_data_source.dart';
import 'package:wol_client/data/models/gateway.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upsertFromSync matches a local gateway by normalized base URL', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          for (final statement in AppDatabase.schema) {
            await db.execute(statement);
          }
        },
      ),
    );
    addTearDown(db.close);

    final local = GatewayLocalDataSource(database: AppDatabase.forTesting(db));
    final now = DateTime.now();
    await local.insert(
      Gateway(
        name: 'Home',
        scheme: 'https',
        baseUrl: 'gateway.example.com',
        apiToken: 'token',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Remote row has no local sync ID yet and a trailing slash on the URL.
    await local.upsertFromSync(
      Gateway(
        syncId: 'remote-1',
        name: 'Home renamed',
        scheme: 'https',
        baseUrl: 'gateway.example.com/',
        apiToken: 'token',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final gateways = await local.getAll();
    expect(gateways, hasLength(1));
    expect(gateways.single.syncId, 'remote-1');
    expect(gateways.single.name, 'Home renamed');
  });
}
