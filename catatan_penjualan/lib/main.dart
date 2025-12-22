import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Auth Pages
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';

// Dashboard
import 'features/dashboard/dashboard_page.dart';
import 'features/dashboard/pendapatan_page.dart';

// Penjualan
import 'features/penjualan/penjualan_page.dart';
import 'features/penjualan/penjualan_form_page.dart';

// Calendar
import 'features/calendar/calendar_page.dart';
import 'features/calendar/daily_sales_page.dart';

// Profile
import 'features/settings/profil_page.dart';

// Reports
import 'features/reports/reports_page.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 === DEBUG: Starting app initialization ===');

  await initializeDateFormatting('id_ID');

  try {
    print('🔥 === DEBUG: Initializing Firebase... ===');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ === DEBUG: Firebase initialized successfully ===');

    // Test Firestore connection
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print('👤 === DEBUG: User is logged in: ${user.email} ===');
      print('🆔 === DEBUG: User UID: ${user.uid} ===');

      // Test Firestore connection
      try {
        final testDoc = await firestore.collection('users').doc(user.uid).get();
        print('📊 === DEBUG: Firestore test successful: ${testDoc.exists} ===');
        if (testDoc.exists) {
          print('📋 === DEBUG: User data: ${testDoc.data()} ===');
        }
      } catch (e) {
        print('❌ === DEBUG ERROR: Firestore test failed: $e ===');
      }
    } else {
      print('👤 === DEBUG: No user logged in ===');
    }
  } catch (e) {
    print('❌ === DEBUG ERROR: Firebase initialization error: $e ===');
  }

  runApp(const ProviderScope(child: MyApp()));
  print('🎉 === DEBUG: App started successfully ===');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeState.navbarColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: themeState.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: themeState.navbarColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeState.navbarColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: themeState.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: themeState.navbarColor,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[800],
        ),
      ),
      themeMode: themeState.themeMode,
      routerConfig: _router(ref),
    );
  }

  GoRouter _router(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;
        final isLoginPage = state.matchedLocation == '/';
        final isRegisterPage = state.matchedLocation == '/register';
        final isAuthPage = isLoginPage || isRegisterPage;

        if (user == null && !isAuthPage) {
          return '/';
        }

        if (user != null && isAuthPage) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/pendapatan',
          builder: (context, state) => const PendapatanPage(),
        ),
        GoRoute(
          path: '/penjualan',
          builder: (context, state) => const PenjualanPage(),
        ),
        GoRoute(
          path: '/penjualan/tambah',
          builder: (context, state) => const PenjualanFormPage(),
        ),
        GoRoute(
          path: '/penjualan/edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return PenjualanFormPage(penjualanId: id);
          },
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/daily-sales/:date',
          builder: (context, state) {
            final dateString = state.pathParameters['date'];
            final date = dateString != null
                ? DateTime.parse(dateString)
                : DateTime.now();
            return DailySalesPage(selectedDate: date);
          },
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Halaman tidak ditemukan',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
