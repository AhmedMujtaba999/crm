import 'package:flutter/material.dart';
import 'splash.dart';
import 'home_shell.dart';
import 'invoice.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const SplashScreen(),
    '/home': (_) => const HomeShell(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/invoice') {
      final workItemId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => const InvoicePage(),
        settings: RouteSettings(arguments: workItemId),
      );
    }
    return null;
  }
}