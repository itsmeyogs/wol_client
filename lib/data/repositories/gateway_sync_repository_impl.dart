import 'package:firebase_core/firebase_core.dart';

import '../datasources/gateway_cloud_data_source.dart';
import '../datasources/gateway_local_data_source.dart';
import '../models/gateway.dart';
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
    final cloudByBaseUrl = {for (final gateway in cloud) _baseUrlKey(gateway): gateway};

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
      final matchedRemote = remote ?? cloudByBaseUrl[_baseUrlKey(gateway)];
      if (matchedRemote == null || gateway.updatedAt.isAfter(matchedRemote.updatedAt)) {
        if (matchedRemote != null) {
          cloudById.remove(matchedRemote.syncId);
          final winner = gateway.copyWith(syncId: matchedRemote.syncId);
          await _cloud.save(winner);
          await _local.update(winner.copyWith(id: gateway.id));
        } else {
          await _cloud.save(gateway);
        }
      } else {
        cloudById.remove(matchedRemote.syncId);
        await _local.upsertFromSync(matchedRemote);
      }
    }
    for (final gateway in cloudById.values) {
      await _local.upsertFromSync(gateway);
    }
  }

  static String _baseUrlKey(Gateway gateway) =>
      '${gateway.scheme.toLowerCase()}://${gateway.baseUrl.toLowerCase().replaceAll(RegExp(r'/+$'), '')}';
}
