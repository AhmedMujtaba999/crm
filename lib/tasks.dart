import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'models.dart';
import 'widgets.dart';
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
        const GradientHeader(title: "Tasks"),
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
                itemBuilder: (_, i) => _taskCard(list[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _taskCard(TaskItem t) {
    final date = DateFormat('M/d/y').format(t.createdAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(t.customerName, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(t.phone, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Text("Created $date", style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          TextButton(
            onPressed: () => _openTaskMenu(t),
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  void _openTaskMenu(TaskItem task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),

          // View task (just show info)
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text("View Task", style: TextStyle(fontWeight: FontWeight.w800)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(task.title),
                  content: Text(
                    "${task.customerName}\n${task.phone}\n${task.email}\n${task.address}",
                  ),
                ),
              );
            },
          ),

          // Delete task
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Delete Task", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
            onTap: () async {
              await AppDb.instance.deleteTask(task.id);
              if (mounted) setState(() {});
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),

          // Activate task
          ListTile(
            leading: const Icon(Icons.play_arrow_outlined),
            title: const Text("Activate Task", style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text("Will open Create page with prefilled customer"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateWorkItemPage(prefillTask: task)),
              );
            },
          ),
        ]),
      ),
    );
  }
}