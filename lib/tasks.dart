import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'models.dart';
import 'widgets.dart';
import 'theme.dart';
import 'create.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Future<List<TaskItem>> _load() async {
    await AppDb.instance.seedTasksIfEmpty();
    return AppDb.instance.listTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        GradientHeader(title: "Tasks", subtitle: "Pending tasks"),
        Expanded(
          child: FutureBuilder<List<TaskItem>>(
            future: _load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) return const EmptyState(text: "No tasks");

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final t = list[i];
                  final date = DateFormat('M/d/y').format(t.createdAt);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(t.customerName, style: const TextStyle(color: AppColors.subText)),
                            const SizedBox(height: 4),
                            Text(t.phone, style: const TextStyle(color: AppColors.subText)),
                            const SizedBox(height: 10),
                            Text("Created $date", style: const TextStyle(color: Colors.grey)),
                          ]),
                        ),
                        TextButton(
                          onPressed: () => _openTaskSheet(t),
                          child: const Text("Open"),
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

  void _openTaskSheet(TaskItem task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _TaskSheet(
        task: task,
        onDelete: () async {
          await AppDb.instance.deleteTask(task.id);
          if (mounted) setState(() {});
          Navigator.pop(context);
        },
        onActivate: () {
          Navigator.pop(context);

          // open create screen with prefill
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateWorkItemPage(prefillTask: task),
            ),
          );
        },
      ),
    );
  }
}

class _TaskSheet extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _TaskSheet({required this.task, required this.onActivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Customer Information", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(task.customerName),
              Text(task.phone),
              Text(task.email),
              Text(task.address),
            ]),
          ),

          const SizedBox(height: 14),

          PrimaryButton(text: "Activate Task", icon: Icons.play_arrow, onTap: onActivate),
          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("Delete Task", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),

          const SizedBox(height: 6),
          const Text(
            "Activating will create a new work item with pre-filled customer details",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
