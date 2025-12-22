import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to pick image from gallery: $e');
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to pick image from camera: $e');
      throw Exception('Gagal mengambil foto: $e');
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User tidak terautentikasi');

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Ukuran file maksimal 10MB');
      }

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ DEBUG: Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to upload profile image: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  Future<String?> getProfileImageUrl() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('ℹ️ DEBUG: No profile image found: $e');
      return null;
    }
  }

  Future<void> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.delete();
      print('✅ DEBUG: Profile image deleted successfully');
    } catch (e) {
      print('ℹ️ DEBUG: Error deleting profile image (may not exist): $e');
    }
  }
}
