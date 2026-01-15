import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create.dart';
import 'work_items.dart';
import 'tasks.dart';
import 'theme.dart';

import 'providers/home_shell_provider.dart';

class HomeShell extends StatefulWidget {
  final int initialTab;
  final String? workTab;

  const HomeShell({
    super.key,
    this.initialTab = 0,
    this.workTab,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeShellProvider>().init(
            initialTab: widget.initialTab,
            initialWorkTab: widget.workTab,
          );
    });
  }

  Widget? _buildFab(HomeShellProvider p) {
    if (p.index == 2) {
      return FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/task_create');
          if (created == true) {
            await p.onTaskCreated();
          }
        },
        child: const Icon(Icons.add_task),
      );
    }
    return null;
  }

  Widget _badgeIcon({required IconData icon, required int count}) {
    if (count <= 0) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeShellProvider>();

    final pages = [
      const CreateWorkItemPage(),
      WorkItemsPage(initialTab: p.workTab),
      const TasksPage(),
    ];

    return PopScope(
      canPop: p.index == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          p.handleBack();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: p.index, children: pages),
        floatingActionButton: _buildFab(p),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: p.index,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          onTap: p.setTab,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Create",
            ),
            BottomNavigationBarItem(
              icon: _badgeIcon(
                icon: Icons.description_outlined,
                count: p.activeWorkItemsCount,
              ),
              label: "Work Items",
            ),
            BottomNavigationBarItem(
              icon: _badgeIcon(
                icon: Icons.check_box_outlined,
                count: p.pendingTasksCount,
              ),
              label: "Tasks",
            ),
          ],
        ),
      ),
    );
  }
}
