import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simpan data user ke Firestore saat registrasi
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      print('=== DEBUG: Saving user profile to Firestore for UID: $uid ===');

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber ?? '',
        'address': address ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'role': 'user',
      }, SetOptions(merge: true));

      print('=== DEBUG: User profile saved successfully ===');
    } catch (e) {
      print('=== DEBUG ERROR: Failed to save user profile: $e ===');
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Update user profile - Method ini harus dipanggil dari profile provider
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('=== DEBUG: Updating user profile for UID: $uid ===');
      print('=== DEBUG: Update data: $data ===');

      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('=== DEBUG: User profile updated successfully ===');
    } catch (e) {
      print('=== DEBUG ERROR: Failed to update user profile: $e ===');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      print('=== DEBUG: Getting user profile for UID: $uid ===');

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('=== DEBUG: User profile found: ${doc.data()} ===');
        return doc.data();
      }

      print('=== DEBUG: No user profile found ===');
      return null;
    } catch (e) {
      print('=== DEBUG ERROR: Failed to get user profile: $e ===');
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    print('=== DEBUG: Streaming user profile for UID: $uid ===');

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        print('=== DEBUG: Stream update for user profile ===');
        return snapshot.data();
      }
      return null;
    }).handleError((e) {
      print('=== DEBUG ERROR: Stream error for user profile: $e ===');
      return null;
    });
  }

  // Simpan penjualan ke Firestore
  Future<String> savePenjualan(Map<String, dynamic> penjualanData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('=== DEBUG: Saving penjualan to Firestore ===');
      print('=== DEBUG: Penjualan data: $penjualanData ===');

      final data = {
        ...penjualanData,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('penjualan').add(data);

      print('=== DEBUG: Penjualan saved with ID: ${docRef.id} ===');
      return docRef.id;
    } catch (e) {
      print('=== DEBUG ERROR: Failed to save penjualan: $e ===');
      throw Exception('Failed to save penjualan: $e');
    }
  }

  // Update penjualan
  Future<void> updatePenjualan(
    String docId,
    Map<String, dynamic> penjualanData,
  ) async {
    try {
      print('=== DEBUG: Updating penjualan with ID: $docId ===');
      print('=== DEBUG: Update data: $penjualanData ===');

      await _firestore.collection('penjualan').doc(docId).update({
        ...penjualanData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('=== DEBUG: Penjualan updated successfully ===');
    } catch (e) {
      print('=== DEBUG ERROR: Failed to update penjualan: $e ===');
      throw Exception('Failed to update penjualan: $e');
    }
  }

  // Hapus penjualan
  Future<void> deletePenjualan(String docId) async {
    try {
      print('=== DEBUG: Deleting penjualan with ID: $docId ===');

      await _firestore.collection('penjualan').doc(docId).delete();

      print('=== DEBUG: Penjualan deleted successfully ===');
    } catch (e) {
      print('=== DEBUG ERROR: Failed to delete penjualan: $e ===');
      throw Exception('Failed to delete penjualan: $e');
    }
  }

  // Get penjualan by user ID
  Stream<List<Map<String, dynamic>>> getPenjualanByUserId(String userId) {
    print('=== DEBUG: Streaming penjualan for user ID: $userId ===');

    return _firestore
        .collection('penjualan')
        .where('userId', isEqualTo: userId)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) {
      print('=== DEBUG: Got ${snapshot.docs.length} penjualan documents ===');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }).handleError((e) {
      print('=== DEBUG ERROR: Stream error for penjualan: $e ===');
      return [];
    });
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      print('=== DEBUG: Checking if user exists: $uid ===');

      final doc = await _firestore.collection('users').doc(uid).get();
      final exists = doc.exists;

      print('=== DEBUG: User exists: $exists ===');
      return exists;
    } catch (e) {
      print('=== DEBUG ERROR: Failed to check user existence: $e ===');
      return false;
    }
  }
}
