import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk perubahan state auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register dengan email & password
  Future<void> registerWithEmail(
      String email, String password, String nama) async {
    try {
      // Create user di Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user!.updateDisplayName(nama);

      // Simpan ke Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': nama,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Kirim email verifikasi
      await userCredential.user!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah. Minimal 6 karakter');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email sudah digunakan. Gunakan email lain');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat registrasi');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Login dengan email & password
  Future<void> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Update last login time
      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Pengguna tidak ditemukan. Silakan registrasi');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password salah. Coba lagi');
      } else if (e.code == 'user-disabled') {
        throw Exception('Akun dinonaktifkan. Hubungi admin');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Terlalu banyak percobaan. Coba lagi nanti');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat login');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Terjadi kesalahan saat logout: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak ditemukan. Pastikan email benar');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat reset password');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update di Firebase Auth
      if (displayName != null && user != null) {
        await user.updateDisplayName(displayName);
        updateData['displayName'] = displayName;
      }

      if (email != null && user != null && user.email != email) {
        // Perlu verifikasi email baru
        await user.verifyBeforeUpdateEmail(email);
        await user.sendEmailVerification();
        updateData['email'] = email;
      }

      if (phoneNumber != null) {
        updateData['phoneNumber'] = phoneNumber;
      }

      // Update di Firestore
      await _firestore.collection('users').doc(uid).update(updateData);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Silakan login ulang untuk mengubah email');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email sudah digunakan. Gunakan email lain');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat update profil');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Pengguna tidak ditemukan');

      if (newPassword.length < 6) {
        throw Exception('Password baru minimal 6 karakter');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Password saat ini salah');
      } else if (e.code == 'weak-password') {
        throw Exception('Password baru terlalu lemah. Minimal 6 karakter');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Silakan login ulang untuk mengubah password');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat ganti password');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Pengguna tidak ditemukan');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user data collection
      await _deleteUserData(user.uid);

      // Delete from Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Password salah');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Silakan login ulang untuk menghapus akun');
      } else {
        throw Exception(e.message ?? 'Terjadi kesalahan saat hapus akun');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Delete user data from collections
  Future<void> _deleteUserData(String uid) async {
    try {
      // Delete user's sales data
      final salesQuery = await _firestore
          .collection('penjualan')
          .where('userId', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in salesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Ignore error for now
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        throw Exception('Gagal mengirim email verifikasi');
      }
    }
  }

  // Reload user data
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Gagal memperbarui data user');
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data profil');
    }
  }

  // Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}

// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
