import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/penjualan_model.dart';
import 'auth_provider.dart';
import '../services/local_pdf_service.dart';

final penjualanProvider =
    StateNotifierProvider<PenjualanNotifier, List<Penjualan>>(
  (ref) {
    print('🚀 DEBUG: Creating penjualanProvider');
    final notifier = PenjualanNotifier();

    // Listen for auth state changes, including initial load
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      print(
          '👂 DEBUG: Auth state changed - previous: ${previous?.value?.email}, current: ${next.value?.email}');
      final previousUser = previous?.value;
      final currentUser = next.value;

      if (previousUser == null && currentUser != null) {
        // User logged in or app started with logged in user: sync with Firestore (which will load data)
        print('🔄 DEBUG: Triggering sync for user login/app start');
        notifier._syncWithFirestore();
      }
      if (previousUser != null && currentUser == null) {
        // User logged out: save current data to local storage
        print('🚪 DEBUG: User logged out, saving data');
        notifier._saveToLocal(previousUser.uid);
      }
    });

    return notifier;
  },
);

class PenjualanNotifier extends StateNotifier<List<Penjualan>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PenjualanNotifier() : super([]);

  @override
  set state(List<Penjualan> value) {
    super.state = value;
    final user = _auth.currentUser;
    if (user != null) {
      _saveToLocal(user.uid); // Save to local storage whenever state changes
    }
  }

  Future<void> _saveToLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'penjualan_$userId';
      final jsonData = json.encode(state.map((e) => e.toMap()).toList());
      await prefs.setString(storageKey, jsonData);
      print(
          '💾 DEBUG: Saved ${state.length} items to local storage for user $userId');
    } catch (e) {
      print('❌ DEBUG ERROR: Error saving to local for user $userId: $e');
    }
  }

  Future<void> _syncWithFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('👤 DEBUG: No user logged in, skipping Firestore sync');
      return;
    }

    print('🔄 DEBUG: Starting Firestore sync for user ${user.uid}');

    try {
      final snapshot = await _firestore
          .collection('penjualan')
          .where('userId', isEqualTo: user.uid)
          .get();

      print('📊 DEBUG: Got ${snapshot.docs.length} documents from Firestore');

      final firestoreData = snapshot.docs.map((doc) {
        final data = doc.data();
        return Penjualan.fromFirestore(data, doc.id);
      }).toList();

      // Sort in memory instead of using orderBy to avoid index requirement
      firestoreData.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      final localUnsyncedData =
          state.where((e) => e.id.startsWith('local_')).toList();
      print('📱 DEBUG: Found ${localUnsyncedData.length} unsynced local items');

      final firestoreIds = firestoreData.map((e) => e.id).toSet();
      final mergedData = [
        ...firestoreData,
        ...localUnsyncedData.where(
            (e) => !firestoreIds.contains(e.id.replaceFirst('local_', ''))),
      ];

      mergedData.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      state = mergedData;
      await _saveToLocal(user.uid);

      print('✅ DEBUG: Merged ${mergedData.length} total items');

      if (localUnsyncedData.isNotEmpty) {
        print(
            '☁️ DEBUG: Syncing ${localUnsyncedData.length} local items to Firestore');
        for (final localItem in localUnsyncedData) {
          await _saveToFirestore(localItem);
        }
      }
    } catch (e) {
      print('❌ DEBUG ERROR: Firestore sync error: $e');
    }
  }

  Future<void> _saveToFirestore(Penjualan penjualan) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ DEBUG ERROR: No user logged in, cannot save to Firestore');
      return;
    }

    try {
      final penjualanData = penjualan.toFirestoreMap();
      penjualanData['userId'] = user.uid;
      penjualanData['updatedAt'] = FieldValue.serverTimestamp();

      print(
          '💽 DEBUG: Saving to Firestore - Name: ${penjualan.nama}, Amount: ${penjualan.total}');

      if (penjualan.id.startsWith('local_')) {
        final docRef =
            await _firestore.collection('penjualan').add(penjualanData);

        final updatedPenjualan = penjualan.copyWith(id: docRef.id);

        state = [
          updatedPenjualan,
          ...state.where((p) => p.id != penjualan.id),
        ];

        await _saveToLocal(user.uid);
        print('🆔 DEBUG: Created new Firestore document with ID: ${docRef.id}');
      } else {
        await _firestore
            .collection('penjualan')
            .doc(penjualan.id)
            .set(penjualanData, SetOptions(merge: true));
        print('📝 DEBUG: Updated existing Firestore document: ${penjualan.id}');
      }
    } catch (e) {
      print('❌ DEBUG ERROR: Firestore save error: $e');
      await _saveToLocal(user.uid);
      rethrow;
    }
  }

  Future<void> add(Penjualan p) async {
    print('➕ DEBUG: Starting add operation');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final penjualanWithId = p.copyWith(id: localId, userId: user.uid);

      print('📝 DEBUG: Adding penjualan: ${penjualanWithId.nama}');

      state = [penjualanWithId, ...state];
      print('💾 DEBUG: Saved to local state. State length: ${state.length}');

      await _saveToLocal(user.uid);
      print('📱 DEBUG: Saved to SharedPreferences');

      await _saveToFirestore(penjualanWithId);
      print('✅ DEBUG: Successfully saved to Firestore');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to add penjualan: $e');
      rethrow;
    }
  }

  Future<void> update(Penjualan p) async {
    print('✏️ DEBUG: Starting update operation for ID: ${p.id}');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updatedPenjualan = p.copyWith(userId: user.uid);

      state = [
        for (final item in state)
          if (item.id == p.id) updatedPenjualan else item,
      ];

      print('💾 DEBUG: Updated in local state');

      await _saveToLocal(user.uid);
      print('📱 DEBUG: Saved to SharedPreferences');

      await _saveToFirestore(updatedPenjualan);
      print('✅ DEBUG: Successfully updated in Firestore');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to update penjualan: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    print('🗑️ DEBUG: Starting delete operation for ID: $id');

    try {
      final user = _auth.currentUser;

      if (user != null && !id.startsWith('local_')) {
        try {
          await _firestore.collection('penjualan').doc(id).delete();
          print('☁️ DEBUG: Deleted from Firestore: $id');
        } catch (e) {
          print(
              '⚠️ DEBUG WARNING: Firestore delete error: $e (continuing with local delete)');
        }
      }

      final newState = state.where((e) => e.id != id).toList();
      state = newState;

      if (user != null) {
        await _saveToLocal(user.uid);
        print(
            '✅ DEBUG: Deleted from local storage. New state length: ${state.length}');
      }
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to delete penjualan: $e');
      rethrow;
    }
  }

  List<Penjualan> getPenjualanByDate(DateTime date) {
    return state.where((p) {
      return p.tanggal.year == date.year &&
          p.tanggal.month == date.month &&
          p.tanggal.day == date.day;
    }).toList();
  }

  int getDailyTotal(DateTime date) {
    return getPenjualanByDate(date)
        .fold<int>(0, (totalSum, p) => totalSum + p.total);
  }

  int getMonthlyTotal(int year, int month) {
    return state
        .where((p) => p.tanggal.year == year && p.tanggal.month == month)
        .fold<int>(0, (totalSum, p) => totalSum + p.total);
  }

  List<Penjualan> getPenjualanByDateRange(DateTime start, DateTime end) {
    return state.where((p) {
      return p.tanggal.isAfter(start.subtract(const Duration(days: 1))) &&
          p.tanggal.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Penjualan> getAll() {
    return state;
  }
}

// Local PDF Service Provider
final pdfShiftServiceProvider = Provider<LocalPdfService>((ref) {
  return LocalPdfService();
});
