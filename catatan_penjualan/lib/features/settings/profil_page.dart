import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isSaving = false;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = ref.read(profileProvider).phoneNumber ?? '';
      _addressController.text = ref.read(profileProvider).address ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_isSaving) return; // Prevent multiple calls

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Input validation
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (address.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Alamat tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number format (basic validation)
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(phone)) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Format nomor telepon tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isSaving = true);

      try {
        // Update display name di Firebase Auth
        await user.updateDisplayName(name);
        await user
            .reload(); // Reload user data to ensure displayName is updated

        // Update profile data di Firestore via provider
        await ref.read(profileProvider.notifier).updateProfileData(
              phone,
              address,
            );

        // Check if update was successful
        final profileState = ref.read(profileProvider);
        if (profileState.error != null) {
          throw Exception(profileState.error);
        }

        // Update juga di Firestore collection users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'displayName': name,
          'phoneNumber': phone,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Verify the data was saved successfully
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final savedPhone = data?['phoneNumber'] as String? ?? '';
          final savedAddress = data?['address'] as String? ?? '';
          final savedName = data?['displayName'] as String? ?? '';

          if (savedPhone == phone &&
              savedAddress == address &&
              savedName == name) {
            // Reload user data to ensure UI is updated
            _loadUserData();

            if (mounted) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Profil berhasil diperbarui'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                _isEditing = false;
              });
            }
          } else {
            throw Exception('Data tidak berhasil disimpan dengan benar');
          }
        } else {
          throw Exception('Data profil tidak ditemukan setelah penyimpanan');
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Password baru tidak cocok'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_newPasswordController.text.length < 6) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Password minimal 6 karakter'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diubah'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isChangingPassword = false;
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeState = ref.watch(themeProvider);

    // Add listener only once
    if (!_listenerAdded) {
      _listenerAdded = true;
      ref.listen<ProfileState>(profileProvider, (previous, next) {
        if (!_isEditing) {
          _phoneController.text = next.phoneNumber ?? '';
          _addressController.text = next.address ?? '';
        }
      });
    }

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          backgroundColor: themeState.navbarColor,
          foregroundColor: Colors.white,
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: Container(
          color: themeState.backgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile
                Center(
                  child: Column(
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final profileState = ref.watch(profileProvider);
                          return CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundImage: profileState.profileImageUrl !=
                                    null
                                ? NetworkImage(profileState.profileImageUrl!)
                                : null,
                            child: profileState.profileImageUrl == null
                                ? Text(
                                    user?.displayName?.isNotEmpty == true
                                        ? user!.displayName![0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'Pengguna',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bergabung: ${_formatDate(user?.metadata.creationTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Edit Profile
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Informasi Profil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.cancel : Icons.edit,
                                color: _isEditing ? Colors.red : Colors.blue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                  if (!_isEditing) {
                                    _loadUserData();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: !_isEditing,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: !_isEditing,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Alamat',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: !_isEditing,
                          maxLines: 3,
                        ),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _updateProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving
                                  ? 'Menyimpan...'
                                  : 'Simpan Perubahan'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Change Password
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ubah Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isChangingPassword ? Icons.cancel : Icons.lock,
                                color: _isChangingPassword
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isChangingPassword = !_isChangingPassword;
                                  if (!_isChangingPassword) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_isChangingPassword) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Password Saat Ini',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Password Baru',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi Password Baru',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: _changePassword,
                              icon: const Icon(Icons.lock_reset),
                              label: const Text('Ubah Password'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Mode Gelap'),
                          value: themeState.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            final notifier = ref.read(themeProvider.notifier);
                            notifier.setTheme(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                          secondary: const Icon(Icons.dark_mode),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.palette),
                          title: const Text('Warna Navbar'),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: themeState.navbarColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          onTap: () => _showColorPickerDialog(
                            context,
                            'Pilih Warna Navbar',
                            themeState.navbarColor,
                            (color) {
                              ref
                                  .read(themeProvider.notifier)
                                  .setNavbarColor(color);
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.format_paint),
                          title: const Text('Warna Background'),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: themeState.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          onTap: () => _showColorPickerDialog(
                            context,
                            'Pilih Warna Background',
                            themeState.backgroundColor,
                            (color) {
                              ref
                                  .read(themeProvider.notifier)
                                  .setBackgroundColor(color);
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifikasi'),
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Tentang Aplikasi'),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Catatan Penjualan',
                              applicationVersion: '1.0.0',
                              applicationLegalese:
                                  '© 2025 Dhian Kurnia Ferdiansyah',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Danger Zone
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zona Berbahaya',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          title: const Text(
                            'Hapus Akun',
                            style: TextStyle(color: Colors.red),
                          ),
                          subtitle:
                              const Text('Aksi ini tidak dapat dibatalkan'),
                          onTap: () {
                            _showDeleteAccountDialog(context);
                          },
                        ),
                        const Divider(color: Colors.red),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () async {
                            try {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun? '
          'Semua data penjualan Anda akan hilang permanen. '
          'Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.delete();
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (mounted) {
                    context.go('/');
                  }
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Hapus Akun',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                  Colors.black,
                  Colors.white,
                ]
                    .map((color) => GestureDetector(
                          onTap: () {
                            onColorSelected(color);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentColor == color
                                    ? Colors.black
                                    : Colors.grey,
                                width: currentColor == color ? 3 : 1,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tidak diketahui';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
