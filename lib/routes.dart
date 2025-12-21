import 'package:flutter/material.dart';
import 'splash.dart';
import 'work_items.dart';
import 'tasks.dart';
import 'create.dart';
import 'invoice.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const SplashScreen(),
    '/home': (_) => const HomeShell(),
    '/create': (_) => const CreateWorkItemPage(),
    '/invoice': (_) => const InvoicePage(),
    '/work-items': (_) => const WorkItemsPage(),
    '/tasks': (_) => const TasksPage(),
  };
}
