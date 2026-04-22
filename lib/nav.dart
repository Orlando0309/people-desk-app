import 'package:go_router/go_router.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/ui/screens/home/home_screen.dart';
import 'package:people_desk/ui/screens/login/login_screen.dart';
import 'package:people_desk/ui/screens/profile/profile_screen.dart';
import 'package:people_desk/ui/screens/menu/menu_screen.dart';
import 'package:people_desk/ui/screens/documents/documents_screen.dart';
import 'package:people_desk/ui/screens/expenses/expenses_screen.dart';
import 'package:people_desk/ui/screens/training/training_screen.dart';
import 'package:people_desk/ui/screens/benefits/benefits_screen.dart';
import 'package:people_desk/ui/screens/recruitment/recruitment_screen.dart';
import 'package:people_desk/ui/screens/offboarding/offboarding_screen.dart';
import 'package:people_desk/ui/shell/tab_shell.dart';

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
                    path: AppRoutes.menu,
                    name: 'menu',
                    pageBuilder: (context, state) => const NoTransitionPage(child: MenuScreen()),
                    routes: [
                      GoRoute(
                        path: 'documents',
                        name: 'documents',
                        builder: (context, state) => const DocumentsScreen(),
                      ),
                      GoRoute(
                        path: 'expenses',
                        name: 'expenses',
                        builder: (context, state) => const ExpensesScreen(),
                      ),
                      GoRoute(
                        path: 'training',
                        name: 'training',
                        builder: (context, state) => const TrainingScreen(),
                      ),
                      GoRoute(
                        path: 'benefits',
                        name: 'benefits',
                        builder: (context, state) => const BenefitsScreen(),
                      ),
                      GoRoute(
                        path: 'recruitment',
                        name: 'recruitment',
                        builder: (context, state) => const RecruitmentScreen(),
                      ),
                      GoRoute(
                        path: 'offboarding',
                        name: 'offboarding',
                        builder: (context, state) => const OffboardingScreen(),
                      ),
                    ],
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

class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String menu = '/menu';
  static const String profile = '/profile';
  static const String payslips = '/payslips';
  static const String support = '/support';
  static const String notifications = '/notifications';
}
