import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tugas.dart';

abstract interface class TugasRepository {
  Future<List<Tugas>> getAll();
  Future<Tugas> add(Tugas tugas);
  Future<void> update(Tugas tugas);
  Future<void> delete(Tugas tugas);
}

class FirestoreTugasRepository implements TugasRepository {
  FirestoreTugasRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<CollectionReference<Map<String, dynamic>>> _collection() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Pengguna Firebase tidak tersedia.');
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  @override
  Future<List<Tugas>> getAll() async {
    final snapshot = await (await _collection()).orderBy('deadline').get();
    return snapshot.docs
        .map((document) => Tugas.fromMap(document.id, document.data()))
        .toList();
  }

  @override
  Future<Tugas> add(Tugas tugas) async {
    final document = await (await _collection()).add(tugas.toMap());
    tugas.id = document.id;
    return tugas;
  }

  @override
  Future<void> update(Tugas tugas) async {
    final id = tugas.id;
    if (id == null) throw StateError('Tugas belum memiliki ID.');
    await (await _collection()).doc(id).update(tugas.toMap());
  }

  @override
  Future<void> delete(Tugas tugas) async {
    final id = tugas.id;
    if (id == null) return;
    await (await _collection()).doc(id).delete();
  }
}

class MemoryTugasRepository implements TugasRepository {
  MemoryTugasRepository([List<Tugas>? initial]) : _items = [...?initial];

  final List<Tugas> _items;
  int _nextId = 0;

  @override
  Future<List<Tugas>> getAll() async => [..._items];

  @override
  Future<Tugas> add(Tugas tugas) async {
    tugas.id ??= 'memory-${_nextId++}';
    _items.add(tugas);
    return tugas;
  }

  @override
  Future<void> update(Tugas tugas) async {}

  @override
  Future<void> delete(Tugas tugas) async => _items.remove(tugas);
}
