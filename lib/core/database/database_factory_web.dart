import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> configureDatabaseFactory() async {
  // Main-thread mode: no SharedWorker to fail behind hosting headers, and the
  // store name is versioned so a broken IndexedDB from older builds is ignored.
  databaseFactory = createDatabaseFactoryFfiWeb(
    noWebWorker: true,
    options: SqfliteFfiWebOptions(
      sqlite3WasmUri: Uri.parse('/sqlite3.wasm'),
      indexedDbName: 'wol_client_v2',
    ),
  );
}
