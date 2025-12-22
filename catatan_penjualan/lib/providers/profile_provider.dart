import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_provider.dart';

class ProfileState {
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? address;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profileImageUrl,
    this.phoneNumber,
    this.address,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    String? profileImageUrl,
    String? phoneNumber,
    String? address,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ProfileNotifier() : super(ProfileState()) {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('👤 DEBUG: Loading profile data');

      await _loadProfileImage();
      await _loadFirestoreProfileData();

      print('✅ DEBUG: Profile data loaded successfully');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to load profile data: $e');
      state = state.copyWith(
          isLoading: false, error: 'Failed to load profile data: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');

      try {
        final downloadUrl = await ref.getDownloadURL();
        state = state.copyWith(profileImageUrl: downloadUrl);
        print('🖼️ DEBUG: Profile image loaded: $downloadUrl');

        // Simpan URL ke Firestore untuk cache
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print(
            'ℹ️ DEBUG: No profile image found in storage, checking Firestore');
        // Coba ambil dari Firestore cache
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final cachedUrl = data?['profileImageUrl'] as String?;
          if (cachedUrl != null && cachedUrl.isNotEmpty) {
            state = state.copyWith(profileImageUrl: cachedUrl);
            print(
                '🖼️ DEBUG: Profile image loaded from Firestore cache: $cachedUrl');
          }
        }
      }
    } catch (e) {
      print('ℹ️ DEBUG: Error loading profile image: $e');
    }
  }

  Future<void> _loadFirestoreProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('👤 DEBUG: No user logged in, skipping Firestore profile load');
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        print('📊 DEBUG: Loaded profile data from Firestore: $data');

        state = state.copyWith(
          phoneNumber: data?['phoneNumber'] as String? ?? '',
          address: data?['address'] as String? ?? '',
          isLoading: false,
        );
      } else {
        print('📝 DEBUG: No profile data in Firestore, creating default');

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'phoneNumber': '',
          'address': '',
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        state = state.copyWith(
          phoneNumber: '',
          address: '',
          isLoading: false,
        );
      }
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to load Firestore profile: $e');
      state = state.copyWith(
          isLoading: false, error: 'Failed to load profile from server');
    }
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
          '📸 DEBUG: Picking image from ${source == ImageSource.gallery ? 'gallery' : 'camera'}');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final ImagePicker picker = ImagePicker();
      XFile? imageFile;

      if (source == ImageSource.gallery) {
        imageFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      } else {
        imageFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      }

      if (imageFile != null) {
        print('📤 DEBUG: Image picked successfully, uploading...');

        final file = File(imageFile.path);
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Ukuran file maksimal 10MB');
        }

        // Upload ke Firebase Storage
        final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();

        print('✅ DEBUG: Profile image uploaded successfully: $downloadUrl');

        // Simpan URL ke Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('💾 DEBUG: Profile image URL saved to Firestore');

        // Update state
        state = state.copyWith(
          profileImageUrl: downloadUrl,
          isLoading: false,
        );
      } else {
        print('ℹ️ DEBUG: No image selected');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to upload profile image: $e');
      state =
          state.copyWith(isLoading: false, error: 'Failed to upload image: $e');
    }
  }

  Future<void> deleteProfileImage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🗑️ DEBUG: Deleting profile image');

      final user = _auth.currentUser;
      if (user == null) return;

      // Hapus dari storage
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.delete();

      // Hapus URL dari Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(profileImageUrl: null, isLoading: false);
      print('✅ DEBUG: Profile image deleted successfully');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to delete profile image: $e');
      state =
          state.copyWith(isLoading: false, error: 'Failed to delete image: $e');
    }
  }

  Future<void> updateProfileData(String phoneNumber, String address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📝 DEBUG: Updating profile data');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final profileData = {
        'phoneNumber': phoneNumber,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      print('✅ DEBUG: Profile data saved to Firestore successfully');
      print('📞 DEBUG: Phone: $phoneNumber, Address: $address');

      state = state.copyWith(
        phoneNumber: phoneNumber,
        address: address,
        isLoading: false,
      );
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to save profile data to Firestore: $e');
      state =
          state.copyWith(isLoading: false, error: 'Failed to save profile: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = ProfileState();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier();

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    final previousUser = previous?.value;
    final currentUser = next.value;

    if (previousUser == null && currentUser != null) {
      notifier._loadProfileData();
    }
    if (previousUser != null && currentUser == null) {
      notifier.reset();
    }
  });

  return notifier;
});
