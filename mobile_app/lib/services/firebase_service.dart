import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Generic Write (Replacing Supabase set)
  Future<void> set(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: true));
  }

  /// Generic Read (Replacing Supabase get)
  Future<Map<String, dynamic>?> get(String collection, String documentId) async {
    final doc = await _firestore.collection(collection).doc(documentId).get();
    return doc.data();
  }

  /// Generic Query (Replacing Supabase getByPrefix or similar)
  Future<List<Map<String, dynamic>>> query(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((d) => d.data()).toList();
  }
}
