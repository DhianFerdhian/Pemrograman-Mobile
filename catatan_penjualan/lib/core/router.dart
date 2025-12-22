import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/penjualan/penjualan_page.dart';
import '../features/penjualan/penjualan_form_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarPage(),
    ),
    GoRoute(
      path: '/penjualan',
      builder: (context, state) => const PenjualanPage(),
      routes: [
        GoRoute(
          path: 'tambah',
          builder: (context, state) => const PenjualanFormPage(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PenjualanFormPage(penjualanId: id);
          },
        ),
      ],
    ),
  ],
);
