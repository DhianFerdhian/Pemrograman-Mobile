import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color navbarColor;
  final Color backgroundColor;
  final Color cardColor;

  ThemeState({
    this.themeMode = ThemeMode.system,
    this.navbarColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.cardColor = Colors.white,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? navbarColor,
    Color? backgroundColor,
    Color? cardColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      navbarColor: navbarColor ?? this.navbarColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ThemeNotifier() : super(ThemeState()) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';
  static const String _navbarColorKey = 'navbar_color';
  static const String _backgroundColorKey = 'background_color';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final savedTheme = prefs.getString(_themeKey);
      ThemeMode themeMode = ThemeMode.system;
      if (savedTheme == 'light') {
        themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        themeMode = ThemeMode.dark;
      }

      // Load navbar color
      final navbarColorValue = prefs.getInt(_navbarColorKey);
      final navbarColor =
          navbarColorValue != null ? Color(navbarColorValue) : Colors.blue;

      // Load background color
      final backgroundColorValue = prefs.getInt(_backgroundColorKey);
      final backgroundColor = backgroundColorValue != null
          ? Color(backgroundColorValue)
          : Colors.white;

      state = ThemeState(
        themeMode: themeMode,
        navbarColor: navbarColor,
        backgroundColor: backgroundColor,
      );

      // Load from Firestore if user is logged in
      await _loadThemeFromFirestore();
    } catch (e) {
      print('❌ DEBUG ERROR: Error loading theme: $e');
      state = ThemeState();
    }
  }

  Future<void> _loadThemeFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc =
          await _firestore.collection('user_settings').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == (data['themeMode'] ?? 'system'),
            orElse: () => ThemeMode.system,
          );

          final navbarColor = data['navbarColor'] != null
              ? Color(data['navbarColor'] as int)
              : Colors.blue;

          final backgroundColor = data['backgroundColor'] != null
              ? Color(data['backgroundColor'] as int)
              : Colors.white;

          state = state.copyWith(
            themeMode: themeMode,
            navbarColor: navbarColor,
            backgroundColor: backgroundColor,
          );

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_themeKey, themeMode.name);
          await prefs.setInt(_navbarColorKey, navbarColor.value);
          await prefs.setInt(_backgroundColorKey, backgroundColor.value);
        }
      }
    } catch (e) {
      print('ℹ️ DEBUG: No theme settings in Firestore or error: $e');
    }
  }

  Future<void> _saveThemeToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_settings').doc(user.uid).set({
        'themeMode': state.themeMode.name,
        'navbarColor': state.navbarColor.value,
        'backgroundColor': state.backgroundColor.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ DEBUG: Theme settings saved to Firestore');
    } catch (e) {
      print('❌ DEBUG ERROR: Failed to save theme to Firestore: $e');
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    // Set appropriate background and card colors based on theme mode
    Color backgroundColor = state.backgroundColor;
    Color cardColor = state.cardColor;

    if (themeMode == ThemeMode.dark) {
      // If switching to dark mode and background is light, set to dark background (not pitch black)
      if (state.backgroundColor == Colors.white ||
          state.backgroundColor.value == Colors.white.value) {
        backgroundColor = const Color(0xFF1E1E1E); // Dark but not pitch black
      }
      // Set dark card color
      if (state.cardColor == Colors.white ||
          state.cardColor.value == Colors.white.value) {
        cardColor = const Color(0xFF2A2A2A); // Dark card color
      }
    } else if (themeMode == ThemeMode.light) {
      // If switching to light mode, set to pure white
      backgroundColor = Colors.white;
      cardColor = Colors.white;
    }

    state = state.copyWith(
      themeMode: themeMode,
      backgroundColor: backgroundColor,
      cardColor: cardColor,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode.name);
      await prefs.setInt(_backgroundColorKey, backgroundColor.value);
      await _saveThemeToFirestore();
    } catch (e) {
      print('❌ DEBUG ERROR: Error saving theme: $e');
    }
  }

  Future<void> setNavbarColor(Color color) async {
    state = state.copyWith(navbarColor: color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_navbarColorKey, color.value);
      await _saveThemeToFirestore();
    } catch (e) {
      print('❌ DEBUG ERROR: Error saving navbar color: $e');
    }
  }

  Future<void> setBackgroundColor(Color color) async {
    state = state.copyWith(backgroundColor: color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backgroundColorKey, color.value);
      await _saveThemeToFirestore();
    } catch (e) {
      print('❌ DEBUG ERROR: Error saving background color: $e');
    }
  }

  void toggleTheme() {
    if (state.themeMode == ThemeMode.light) {
      setTheme(ThemeMode.dark);
    } else {
      setTheme(ThemeMode.light);
    }
  }
}
