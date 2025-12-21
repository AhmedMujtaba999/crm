import 'package:flutter/material.dart';
import 'splash.dart';
import 'work_items.dart';
import 'invoice.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const SplashScreen(),
    '/home': (_) => const HomeShell(),
    '/invoice': (_) => const InvoicePage(),
  };
}