import 'package:crm/authgate.dart';
import 'package:crm/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'splash.dart';
import 'home_shell.dart';
import 'task_create.dart';
import 'invoice.dart';
import 'providers/task_create_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/home_shell_provider.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------------- Splash ----------------
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      // ---------------- Home ----------------
      case '/home':
        {
          int tab = 0;
          String? workTab;

          final args = settings.arguments;
          if (args is Map) {
            if (args['tab'] is int) tab = args['tab'];
            if (args['workTab'] is String) workTab = args['workTab'];
          }

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => HomeShell(initialTab: tab, workTab: workTab),
          );
        }

      // ---------------- Invoice (WITH PROVIDER) ----------------
      case '/invoice':
        {
          final args = settings.arguments;

          String? workItemId;

          // Accept: String OR {'id': '...'}
          if (args is String && args.trim().isNotEmpty) {
            workItemId = args.trim();
          } else if (args is Map && args['id'] is String) {
            workItemId = (args['id'] as String).trim();
          }

          // Safety fallback
          if (workItemId == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Missing Work Item ID for invoice.")),
              ),
            );
          }

          // ✅ Correct Provider Injection
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ChangeNotifierProvider(
              create: (_) => InvoiceProvider()..load(workItemId!),
              child: const InvoicePage(),
            ),
          );
        }

      // ---------------- Create Task ----------------
      case '/task_create':
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => TaskCreateProvider(),
            child: const CreateTaskPage(),
          ),
          settings: settings,
        );

      //--------------Auth-----------------
      case '/auth':
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: AuthGate(),
          ),
          settings: settings,
        );

      // ---------------- Fallback ----------------
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
