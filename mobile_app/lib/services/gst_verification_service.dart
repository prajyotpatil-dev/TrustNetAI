import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for validating GSTIN format and verifying against Firestore database.
class GSTVerificationService {
  static final _firestore = FirebaseFirestore.instance;

  /// GSTIN format: 2-digit state code + 10-char PAN + 1 entity code + Z + 1 check digit
  /// Example: 22AAAAA0000A1Z5
  static final _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}[Z]{1}[A-Z0-9]{1}$',
  );

  /// Valid Indian state codes (01–38)
  static const _validStateCodes = {
    '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
    '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
    '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
    '31', '32', '33', '34', '35', '36', '37', '38',
  };

  /// Validates GSTIN format locally (no network call).
  static String? validateFormat(String gstin) {
    if (gstin.isEmpty) return 'GSTIN is required for business registration';
    if (gstin.length != 15) return 'GSTIN must be exactly 15 characters';
    if (!_gstinRegex.hasMatch(gstin)) return 'Invalid GSTIN format';

    final stateCode = gstin.substring(0, 2);
    if (!_validStateCodes.contains(stateCode)) {
      return 'Invalid state code: $stateCode';
    }

    return null; // Format is valid
  }

  /// Verifies GSTIN exists in the Firestore `valid_gst` collection.
  /// Uses direct document ID lookup (faster than query, no index needed).
  /// Returns business name if found, null if not found.
  static Future<String?> verifyInDatabase(String gstin) async {
    try {
      debugPrint('🔍 GST Lookup: Checking GSTIN "$gstin" in valid_gst collection...');
      
      final doc = await _firestore
          .collection('valid_gst')
          .doc(gstin)
          .get();

      debugPrint('🔍 GST Lookup: doc.exists = ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        final verified = data?['verified'] as bool? ?? false;
        debugPrint('🔍 GST Lookup: verified = $verified, businessName = ${data?['businessName']}');
        
        if (verified) {
          return data?['businessName'] as String? ?? 'Verified Business';
        }
      }
      
      debugPrint('🔍 GST Lookup: GSTIN "$gstin" not found or not verified');
      return null;
    } catch (e) {
      debugPrint('❌ GST verification error: $e');
      return null;
    }
  }

  /// Full verification: format check + database lookup.
  /// Returns a [GSTVerificationResult].
  static Future<GSTVerificationResult> verify(String gstin) async {
    final trimmed = gstin.trim().toUpperCase();

    // Step 1: Format validation
    final formatError = validateFormat(trimmed);
    if (formatError != null) {
      return GSTVerificationResult(
        isValid: false,
        errorMessage: formatError,
      );
    }

    // Step 2: Database lookup
    final businessName = await verifyInDatabase(trimmed);
    if (businessName == null) {
      return GSTVerificationResult(
        isValid: false,
        errorMessage: 'GSTIN not found in verification database. Please use a valid GSTIN.',
      );
    }

    return GSTVerificationResult(
      isValid: true,
      businessName: businessName,
      verifiedGstin: trimmed,
    );
  }

  /// Seeds the demo GST database. Safe to call multiple times —
  /// checks if data already exists before writing.
  static Future<void> seedDemoData() async {
    try {
      // Quick check: if first demo doc already exists, skip seeding
      final checkDoc = await _firestore
          .collection('valid_gst')
          .doc(_demoGSTData.first['gstin'] as String)
          .get();
      
      if (checkDoc.exists) {
        debugPrint('✅ GST demo data already seeded (${_demoGSTData.length} records)');
        return;
      }

      debugPrint('📝 Seeding GST demo data...');
      final batch = _firestore.batch();
      for (final entry in _demoGSTData) {
        final docRef = _firestore.collection('valid_gst').doc(entry['gstin'] as String);
        batch.set(docRef, entry);
      }
      await batch.commit();
      debugPrint('✅ Seeded ${_demoGSTData.length} GST demo records into valid_gst collection');
    } catch (e) {
      debugPrint('❌ Failed to seed GST data: $e');
    }
  }

  static final List<Map<String, dynamic>> _demoGSTData = [
    {
      'gstin': '22AAAAA0000A1Z5',
      'businessName': 'ABC Traders Pvt Ltd',
      'state': 'Chhattisgarh',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '27AABCU9603R1ZM',
      'businessName': 'TrustNet Logistics',
      'state': 'Maharashtra',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '29AAGCR4375J1ZN',
      'businessName': 'Rapid Freight Solutions',
      'state': 'Karnataka',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '07AADCB2230M1ZT',
      'businessName': 'Delhi Supply Chain Co',
      'state': 'Delhi',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '33AABCT1332L1ZL',
      'businessName': 'Tamil Transport Hub',
      'state': 'Tamil Nadu',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '24AADCJ5611G1Z2',
      'businessName': 'Gujarat MSME Traders',
      'state': 'Gujarat',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '06AALCA5765E1ZE',
      'businessName': 'Haryana Bulk Movers',
      'state': 'Haryana',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '36AABCF8078K1ZQ',
      'businessName': 'Telangana Fresh Cargo',
      'state': 'Telangana',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '19AABCU9603R1ZV',
      'businessName': 'Kolkata Express Ltd',
      'state': 'West Bengal',
      'verified': true,
      'type': 'Regular',
    },
    {
      'gstin': '32AABCR7531P1ZD',
      'businessName': 'Kerala Spice Logistics',
      'state': 'Kerala',
      'verified': true,
      'type': 'Regular',
    },
  ];
}

/// Result object for GST verification.
class GSTVerificationResult {
  final bool isValid;
  final String? businessName;
  final String? verifiedGstin;
  final String? errorMessage;

  const GSTVerificationResult({
    required this.isValid,
    this.businessName,
    this.verifiedGstin,
    this.errorMessage,
  });
}
