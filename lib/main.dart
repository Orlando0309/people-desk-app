import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/nav.dart';
import 'package:people_desk/state/attendance_controller.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/state/leave_controller.dart';
import 'package:people_desk/state/notifications_controller.dart';
import 'package:people_desk/state/payroll_controller.dart';
import 'package:people_desk/state/support_controller.dart';
import 'package:people_desk/state/theme_controller.dart';
import 'package:people_desk/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthController _auth;
  late final ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _theme = ThemeController();
    // Fire and forget: router redirect + screens will react.
    _auth.bootstrap();
    // Initialize theme from saved preferences
    _theme.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _theme),
        ChangeNotifierProvider(create: (_) => AttendanceController()),
        ChangeNotifierProvider(create: (_) => LeaveController()),
        ChangeNotifierProvider(create: (_) => PayrollController()),
        ChangeNotifierProvider(create: (_) => SupportController()),
        ChangeNotifierProvider(create: (_) => NotificationsController()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthController>();
          final theme = context.watch<ThemeController>();
          return MaterialApp.router(
            title: 'PeopleDesk',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: theme.themeMode,
            routerConfig: AppRouter.create(auth),
          );
        },    
      ),
    );
  }
}
