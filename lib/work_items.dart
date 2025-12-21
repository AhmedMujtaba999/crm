import 'package:flutter/material.dart';
import 'widgets.dart';
import 'storage.dart';
import 'models.dart';
import 'theme.dart';
import 'tasks.dart';
import 'create.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CreateWorkItemPage(),
      const WorkItemsPage(),
      const TasksPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: "Work Items"),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: "Tasks"),
        ],
      ),
    );
  }
}

class WorkItemsPage extends StatefulWidget {
  const WorkItemsPage({super.key});

  @override
  State<WorkItemsPage> createState() => _WorkItemsPageState();
}

class _WorkItemsPageState extends State<WorkItemsPage> {
  bool activeSelected = true;

  Future<List<WorkItem>> _load() {
    return AppDb.instance.listWorkItems(activeSelected ? 'active' : 'completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          title: "Work Items",
          child: PillSwitch(
            leftSelected: activeSelected,
            leftText: "Active",
            rightText: "Completed",
            onLeft: () => setState(() => activeSelected = true),
            onRight: () => setState(() => activeSelected = false),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<WorkItem>>(
            future: _load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) return const EmptyState(text: "No work items");

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final it = list[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(it.phone, style: const TextStyle(color: AppColors.subText)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(activeSelected ? "Active" : "Completed",
                                style: const TextStyle(color: AppColors.subText)),
                            Text("\$${it.total.toStringAsFixed(2)}",
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
