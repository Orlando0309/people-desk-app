import 'package:go_router/go_router.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/ui/screens/attendance/attendance_screen.dart';
import 'package:people_desk/ui/screens/home/home_screen.dart';
import 'package:people_desk/ui/screens/leave/leave_screen.dart';
import 'package:people_desk/ui/screens/login/login_screen.dart';
import 'package:people_desk/ui/screens/notifications/notifications_screen.dart';
import 'package:people_desk/ui/screens/payslips/payslip_detail_screen.dart';
import 'package:people_desk/ui/screens/payslips/payslips_screen.dart';
import 'package:people_desk/ui/screens/profile/profile_screen.dart';
import 'package:people_desk/ui/screens/support/support_screen.dart';
import 'package:people_desk/ui/screens/support/ticket_detail_screen.dart';
import 'package:people_desk/ui/shell/tab_shell.dart';

/// GoRouter configuration for app navigation
///
/// This uses go_router for declarative routing, which provides:
/// - Type-safe navigation
/// - Deep linking support (web URLs, app links)
/// - Easy route parameters
/// - Navigation guards and redirects
///
/// To add a new route:
/// 1. Add a route constant to AppRoutes below
/// 2. Add a GoRoute to the routes list
/// 3. Navigate using context.go() or context.push()
/// 4. Use context.pop() to go back.
class AppRouter {
  static GoRouter create(AuthController auth) => GoRouter(
        initialLocation: AppRoutes.home,
        refreshListenable: auth,
        redirect: (context, state) {
          final isLoggingIn = state.matchedLocation == AppRoutes.login;
          final isAuthed = auth.isAuthed;

          if (!isAuthed && !isLoggingIn) return AppRoutes.login;
          if (isAuthed && isLoggingIn) return AppRoutes.home;
          return null;
        },
        routes: [
          GoRoute(
            path: AppRoutes.login,
            name: 'login',
            pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => TabShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.home,
                    name: 'home',
                    pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.attendance,
                    name: 'attendance',
                    pageBuilder: (context, state) => const NoTransitionPage(child: AttendanceScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.leave,
                    name: 'leave',
                    pageBuilder: (context, state) => const NoTransitionPage(child: LeaveScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.payslips,
                    name: 'payslips',
                    pageBuilder: (context, state) => const NoTransitionPage(child: PayslipsScreen()),
                    routes: [
                      GoRoute(
                        path: ':id',
                        name: 'payslipDetail',
                        builder: (context, state) => PayslipDetailScreen(payslipId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.support,
                    name: 'support',
                    pageBuilder: (context, state) => const NoTransitionPage(child: SupportScreen()),
                    routes: [
                      GoRoute(
                        path: 'tickets/:id',
                        name: 'ticketDetail',
                        builder: (context, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.notifications,
                    name: 'notifications',
                    pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.profile,
                    name: 'profile',
                    pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}

/// Route path constants
/// Use these instead of hard-coding route strings
class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String attendance = '/attendance';
  static const String leave = '/leave';
  static const String payslips = '/payslips';
  static const String support = '/support';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
}
