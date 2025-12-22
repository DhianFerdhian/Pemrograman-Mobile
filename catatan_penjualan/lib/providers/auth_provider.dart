import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthState {
  final User? user;
  final String? error;
  final bool isLoading;

  AuthState({
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    User? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState()) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      print('🔄 DEBUG: Auth state changed. User: ${user?.email}');
      state = state.copyWith(user: user);
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    print('🔐 DEBUG: Starting login for email: $email');

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      try {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('📅 DEBUG: Updated last login timestamp');
      } catch (e) {
        print('⚠️ DEBUG WARNING: Failed to update last login: $e');
      }

      state = state.copyWith(
        user: userCredential.user,
        isLoading: false,
        error: null,
      );

      print(
          '✅ DEBUG: Login successful for user: ${userCredential.user?.email}');
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'Email tidak ditemukan. Silakan daftar terlebih dahulu.';
          break;
        case 'wrong-password':
          errorMsg = 'Password salah. Silakan coba lagi.';
          break;
        case 'invalid-email':
          errorMsg = 'Format email tidak valid';
          break;
        case 'user-disabled':
          errorMsg = 'Akun telah dinonaktifkan';
          break;
        case 'too-many-requests':
          errorMsg = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          errorMsg = 'Koneksi internet bermasalah. Periksa koneksi Anda.';
          break;
        default:
          errorMsg = 'Login gagal: ${e.message}';
      }

      print('❌ DEBUG ERROR: Login failed: $errorMsg');

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } catch (e) {
      print('❌ DEBUG ERROR: Login unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan sistem. Coba lagi nanti.',
      );
    }
  }

  Future<void> register(
      String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);

    print(
        '📝 DEBUG: Starting registration for email: $email, name: $displayName');

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      print(
          '👤 DEBUG: Firebase Auth user created: ${userCredential.user?.uid}');

      try {
        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.updateProfile(displayName: displayName);
        print('🏷️ DEBUG: Display name updated in Auth');
      } catch (e) {
        print('⚠️ DEBUG WARNING: Failed to update display name in Auth: $e');
      }

      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'displayName': displayName,
          'phoneNumber': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));

        print('✅ DEBUG: User profile saved to Firestore successfully');
      } catch (e) {
        print('❌ DEBUG ERROR: Failed to save user profile to Firestore: $e');
      }

      state = state.copyWith(
        user: userCredential.user,
        isLoading: false,
        error: null,
      );

      print('🎉 DEBUG: Registration successful');
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'Email sudah digunakan. Silakan gunakan email lain.';
          break;
        case 'weak-password':
          errorMsg = 'Password terlalu lemah. Minimal 6 karakter.';
          break;
        case 'invalid-email':
          errorMsg = 'Format email tidak valid';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Registrasi dengan email/password tidak diizinkan';
          break;
        default:
          errorMsg = 'Registrasi gagal: ${e.message}';
      }

      print('❌ DEBUG ERROR: Registration failed: $errorMsg');

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } catch (e) {
      print('❌ DEBUG ERROR: Registration unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan sistem. Coba lagi nanti.',
      );
    }
  }

  Future<void> logout() async {
    print('🚪 DEBUG: Logging out user');
    await FirebaseAuth.instance.signOut();
    state = AuthState();
    print('✅ DEBUG: Logout successful');
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> resetPassword(String email) async {
    try {
      print('📧 DEBUG: Sending password reset email to: $email');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('✅ DEBUG: Password reset email sent successfully');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to send password reset email: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      print('🔄 DEBUG: Reloading user data');
      await FirebaseAuth.instance.currentUser?.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      state = state.copyWith(user: updatedUser);
      print('✅ DEBUG: User data reloaded successfully');
    } catch (e) {
      print('⚠️ DEBUG WARNING: Failed to reload user: $e');
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) {
    return FirebaseAuth.instance.authStateChanges();
  },
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user != null;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});
