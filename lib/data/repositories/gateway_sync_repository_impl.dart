import 'package:firebase_core/firebase_core.dart';

import '../datasources/gateway_cloud_data_source.dart';
import '../datasources/gateway_local_data_source.dart';
import '../../domain/repositories/gateway_sync_repository.dart';

class GatewaySyncRepositoryImpl implements GatewaySyncRepository {
  GatewaySyncRepositoryImpl({required this._local, required this._cloud});

  final GatewayLocalDataSource _local;
  final GatewayCloudDataSource _cloud;

  @override
  Future<void> sync() async {
    final tombstones = await _local.getTombstones();
    final cloud = await _cloud.getAll();
    final deletedIds = await _cloud.getDeletedIds();
    final cloudById = {for (final gateway in cloud) gateway.syncId!: gateway};

    for (final syncId in tombstones) {
      try {
        await _cloud.markDeleted(syncId);
        await _local.removeTombstone(syncId);
      } on FirebaseException catch (exception) {
        if (exception.code != 'not-found') rethrow;
        await _local.removeTombstone(syncId);
      }
      cloudById.remove(syncId);
    }

    var local = await _local.getAll();
    for (final gateway in local) {
      if (gateway.syncId != null && deletedIds.contains(gateway.syncId)) {
        await _local.removeBySyncId(gateway.syncId!);
      }
    }
    local = await _local.getAll();
    final localById = {
      for (final gateway in local)
        if (gateway.syncId != null) gateway.syncId!: gateway,
    };
    for (final gateway in localById.values) {
      final remote = cloudById.remove(gateway.syncId);
      if (remote == null || gateway.updatedAt.isAfter(remote.updatedAt)) {
        await _cloud.save(gateway);
      } else {
        await _local.upsertFromSync(remote);
      }
    }
    for (final gateway in cloudById.values) {
      await _local.upsertFromSync(gateway);
    }
  }
}
