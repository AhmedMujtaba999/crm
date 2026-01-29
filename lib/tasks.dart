import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crm/models/models.dart';
import 'widgets.dart';
import 'theme.dart';
import 'create.dart';
import 'package:crm/providers/task_provider.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TasksProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TasksProvider>();

    final now = DateTime.now();
    final isTodayMode = p.filterDate == null;
    final shownDate = isTodayMode
        ? DateTime(now.year, now.month, now.day)
        : p.filterDate!;

    final line1 = isTodayMode ? "Today" : DateFormat('EEEE').format(shownDate);
    final line2 = isTodayMode
        ? DateFormat('EEEE, d MMM').format(shownDate)
        : DateFormat('d MMM, y').format(shownDate);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const GradientHeader(title: "Tasks"),

          /// 🔹 DATE BANNER (UNCHANGED)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withOpacity(0.22)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _iconPill(
                    icon: Icons.calendar_month,
                    tooltip: "Pick date",
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: shownDate,
                        firstDate: DateTime(now.year - 3),
                        lastDate: DateTime(now.year + 3),
                      );
                      if (picked != null) {
                        await p.pickDate(picked);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  if (!isTodayMode)
                    _iconPill(
                      icon: Icons.today,
                      tooltip: "Back to Today",
                      onTap: p.clearFilter,
                    ),
                ],
              ),
            ),
          ),

          /// 🔹 TASK LIST
          Expanded(
            child: p.loading
                ? const Center(child: CircularProgressIndicator())
                : p.tasks.isEmpty
                ? const EmptyState(text: "No tasks")
                : RefreshIndicator(
                    onRefresh: p.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: p.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _taskCard(context, p.tasks[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _iconPill({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, TaskItem t) {
    final sched = DateFormat('M/d/y').format(t.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.customerName,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(t.phone, style: const TextStyle(color: Colors.grey)),
                if (t.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(t.email, style: const TextStyle(color: Colors.grey)),
                ],
                if (t.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(t.address, style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 10),

                if (t.services.isNotEmpty) ...[
                  const Text(
                    "Services:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  ...t.services.map(
                    (s) => Text(
                      '${s.name}: \$${s.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Text(
                  "Scheduled $sched",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openTaskMenu(context, t),
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  void _openTaskMenu(BuildContext context, TaskItem task) {
    final p = context.read<TasksProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text(
                "View Task",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(task.title),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(task.customerName),
                          Text(task.phone),
                          if (task.email.isNotEmpty) Text(task.email),
                          if (task.address.isNotEmpty) Text(task.address),

                          const SizedBox(height: 12),

                          Text(
                            "Scheduled: ${DateFormat('EEE, MMM d, y').format(task.scheduledAt)}",
                          ),

                          const SizedBox(height: 16),

                          /// ✅ SERVICES SECTION
                          if (task.services.isNotEmpty) ...[
                            const Text(
                              "Services",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ...task.services.map(
                              (s) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${s.name} (ID: ${s.id})'),
                                  Text("\$${s.amount.toStringAsFixed(2)}"),
                                ],
                              ),
                            ),
                          ] else
                            const Text("No services added"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                "Delete Task",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                await p.delete(task);
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text(
                "Activate Task",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                "Will open Create page with prefilled customer",
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateWorkItemPage(
                      prefillTask: task,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
