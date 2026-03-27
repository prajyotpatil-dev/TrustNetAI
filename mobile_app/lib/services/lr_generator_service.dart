import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LRGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> generateLRNumber(String roleCode) async {
    final counterRef = _firestore.collection('counters').doc('lr');
    final currentYear = DateTime.now().year;
    
    try {
      final sequence = await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        
        if (!snapshot.exists) {
          // Initialize if the counter collection hasn't been created yet
          transaction.set(counterRef, {
            'year': currentYear,
            'current': 1,
          });
          return 1;
        }

        final data = snapshot.data()!;
        final dbYear = data['year'] as int? ?? currentYear;
        var current = data['current'] as int? ?? 0;

        if (dbYear != currentYear) {
          // Year rollover resets counter cleanly
          current = 1;
        } else {
          current += 1;
        }

        transaction.update(counterRef, {
          'year': currentYear,
          'current': current,
        });

        return current;
      });

      // Format precisely as requested: {COMPANY}-{ROLE}-{YEAR}-{SEQUENCE}
      // Example: TN-TR-2026-000234
      final seqString = sequence.toString().padLeft(6, '0');
      return 'TN-$roleCode-$currentYear-$seqString';
      
    } catch (e) {
      debugPrint('Error generating LR Number (atomic failure): $e');
      rethrow;
    }
  }
}
