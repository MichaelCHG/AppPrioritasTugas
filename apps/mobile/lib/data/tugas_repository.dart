import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SharedPreferencesTugasRepository implements TugasRepository {
  SharedPreferencesTugasRepository({required this.userId});

  final String userId;

  String get _storageKey => 'tugas_cache_$userId';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<Tugas>> getAll() async {
    final encoded = (await _prefs).getString(_storageKey);
    if (encoded == null) return [];
    final records = jsonDecode(encoded) as List<dynamic>;
    return records.map((record) {
      final map = Map<String, dynamic>.from(record as Map);
      final id = map.remove('id') as String;
      return Tugas.fromMap(id, map);
    }).toList();
  }

  Future<bool> get hasStoredData async =>
      (await _prefs).containsKey(_storageKey);

  Future<void> replaceAll(List<Tugas> tugas) => _writeAll(tugas);

  @override
  Future<Tugas> add(Tugas tugas) async {
    tugas.id ??= 'local-${DateTime.now().microsecondsSinceEpoch}';
    final items = await getAll();
    items.removeWhere((item) => item.id == tugas.id);
    items.add(tugas);
    await _writeAll(items);
    return tugas;
  }

  @override
  Future<void> update(Tugas tugas) async {
    final items = await getAll();
    final index = items.indexWhere((item) => item.id == tugas.id);
    if (index < 0) throw StateError('Tugas tidak ditemukan di cache lokal.');
    items[index] = tugas;
    await _writeAll(items);
  }

  @override
  Future<void> delete(Tugas tugas) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == tugas.id);
    await _writeAll(items);
  }

  Future<void> _writeAll(List<Tugas> tugas) async {
    final records = tugas.map((item) {
      return {
        ...item.toMap(),
        'id': item.id,
        'deadline': item.deadline.toIso8601String(),
      };
    }).toList();
    await (await _prefs).setString(_storageKey, jsonEncode(records));
  }
}

class CachedTugasRepository implements TugasRepository {
  CachedTugasRepository({required this.remote, required this.cache});

  final TugasRepository remote;
  final SharedPreferencesTugasRepository cache;

  @override
  Future<List<Tugas>> getAll() async {
    try {
      final items = await remote.getAll();
      await _updateCache(() => cache.replaceAll(items));
      return items;
    } catch (error, stackTrace) {
      try {
        if (await cache.hasStoredData) return await cache.getAll();
      } catch (cacheError) {
        debugPrint('Gagal membaca cache tugas: $cacheError');
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Tugas> add(Tugas tugas) async {
    final saved = await remote.add(tugas);
    await _updateCache(() => cache.add(saved));
    return saved;
  }

  @override
  Future<void> update(Tugas tugas) async {
    await remote.update(tugas);
    await _updateCache(() => cache.update(tugas));
  }

  @override
  Future<void> delete(Tugas tugas) async {
    await remote.delete(tugas);
    await _updateCache(() => cache.delete(tugas));
  }

  Future<void> _updateCache(Future<void> Function() update) async {
    try {
      await update();
    } catch (error) {
      debugPrint('Gagal memperbarui cache tugas: $error');
    }
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
