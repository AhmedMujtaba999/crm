import 'package:crm/providers/create_work_item_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'routes.dart';
import 'storage.dart';
import 'providers/work_items_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupSystemUI();

  // Initialize local database before app starts
  await AppDb.instance.init();

  runApp(
    MultiProvider(

      providers:[
        ChangeNotifierProvider(create: (_)=> CreateWorkItemProvider(),),
         ChangeNotifierProvider(
        create: (_) => WorkItemsProvider(),
        
      ),
      ],
      child: MyApp(),
    ),
  );

  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: '/',
    );
  }
}
