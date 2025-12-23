import 'package:flutter/material.dart';
import 'theme.dart';
import 'create.dart';
import 'work_items.dart';
import 'tasks.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  // this is the key: WorkItems should open on completed only when coming from invoice
  bool workItemsInitialCompleted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['tab'] == 'completed') {
      setState(() {
        index = 1; // Work Items tab
        workItemsInitialCompleted = true; // force completed tab ONCE
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CreateWorkItemPage(),
      WorkItemsPage(initialCompleted: workItemsInitialCompleted),
      const TasksPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          setState(() {
            index = i;

            // if user manually goes to WorkItems later, default to Active
            if (i != 1) return;
            workItemsInitialCompleted = false;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: "Work Items"),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: "Tasks"),
        ],
      ),
    );
  }
}
