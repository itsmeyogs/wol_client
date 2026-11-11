import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/domain/repositories/gateway_sync_repository.dart';
import 'package:wol_client/domain/usecases/gateway_sync_usecase.dart';
import 'package:wol_client/presentation/controllers/gateway_sync_controller.dart';

void main() {
  test('queues one retry instead of running concurrent syncs', () async {
    final gate = Completer<void>();
    var calls = 0;
    final repository = _FakeSyncRepository(() async {
      calls++;
      await gate.future;
    });
    final controller = GatewaySyncController(SyncGateways(repository));

    final first = controller.sync();
    await controller.sync();
    expect(calls, 1);

    gate.complete();
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
  });
}

class _FakeSyncRepository implements GatewaySyncRepository {
  _FakeSyncRepository(this.action);
  final Future<void> Function() action;

  @override
  Future<void> sync() => action();
}
