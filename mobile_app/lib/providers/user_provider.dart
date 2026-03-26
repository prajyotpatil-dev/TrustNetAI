import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  UserModel? _user;
  bool _isLoading = false;

  UserProvider(this._firebaseService);

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _firebaseService.get('users', uid);
      if (data != null) {
        _user = UserModel.fromMap(data, uid);
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically provisions a user doc if it doesn't exist.
  Future<void> ensureUserExists(
    User firebaseUser, {
    required String role,
    String? name,
    String? email,
    String? phone,
    String? gstin,
  }) async {
    try {
      final existingData = await _firebaseService.get('users', firebaseUser.uid);

      if (existingData == null) {
        // Document does not exist. Create it!
        final data = <String, dynamic>{
          'uid': firebaseUser.uid,
          'role': role,
          'createdAt': DateTime.now().toIso8601String(),
          'name': name ?? firebaseUser.displayName ?? 'New User',
          'email': email ?? firebaseUser.email ?? '',
          'phone': phone ?? firebaseUser.phoneNumber ?? '',
        };

        if (gstin != null && gstin.isNotEmpty) {
          data['gstin'] = gstin;
        }

        await _firebaseService.set('users', firebaseUser.uid, data);
        
        // After creation, load to state
        await fetchUserProfile(firebaseUser.uid);
      } else {
        // Document exists, just load it into state
        _user = UserModel.fromMap(existingData, firebaseUser.uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to ensure user exists: $e');
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
