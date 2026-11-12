import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gateway.dart';

class GatewayCloudDataSource {
  GatewayCloudDataSource({required this._firestore, required this._auth});

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _gateways {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication is required for sync.');
    }
    return _firestore.collection('users').doc(uid).collection('gateways');
  }

  CollectionReference<Map<String, dynamic>> get _deletes {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Authentication is required for sync.');
    return _firestore.collection('users').doc(uid).collection('gatewayDeletes');
  }

  Future<List<Gateway>> getAll() async {
    final snapshot = await _gateways.get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  Future<void> save(Gateway gateway) async {
    final syncId = gateway.syncId;
    if (syncId == null) throw StateError('Gateway sync ID is required.');
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Authentication is required for sync.');
    await _deletes.doc(syncId).delete();
    await _gateways.doc(syncId).set({
      'name': gateway.name,
      'scheme': gateway.scheme,
      'baseUrl': gateway.baseUrl,
      'apiToken': gateway.apiToken,
      'ownerId': uid,
      'createdAt': Timestamp.fromDate(gateway.createdAt),
      'updatedAt': Timestamp.fromDate(gateway.updatedAt),
    });
  }

  Future<void> delete(String syncId) => _gateways.doc(syncId).delete();

  Future<void> deleteAccountData() async {
    for (final collection in [_gateways, _deletes]) {
      while (true) {
        final snapshot = await collection.limit(400).get();
        if (snapshot.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final document in snapshot.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
  }

  Future<List<String>> getDeletedIds() async =>
      (await _deletes.get()).docs.map((document) => document.id).toList();

  Future<void> markDeleted(String syncId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Authentication is required for sync.');
    await _gateways.doc(syncId).delete();
    await _deletes.doc(syncId).set({
      'ownerId': uid,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  static Gateway _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Gateway(
      syncId: document.id,
      name: data['name'] as String,
      scheme: data['scheme'] as String,
      baseUrl: data['baseUrl'] as String,
      apiToken: data['apiToken'] as String,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static DateTime _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => throw const FormatException('Invalid gateway timestamp.'),
  };
}
