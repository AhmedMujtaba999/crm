import 'package:flutter/material.dart';
import 'widgets.dart';
import 'theme.dart';
import 'storage.dart';
import 'models.dart';

class WorkItemsPage extends StatefulWidget {
  final bool initialCompleted;
  const WorkItemsPage({super.key, this.initialCompleted = false});

  @override
  State<WorkItemsPage> createState() => _WorkItemsPageState();
}

class _WorkItemsPageState extends State<WorkItemsPage> {
  late bool activeSelected;

  @override
  void initState() {
    super.initState();
    activeSelected = !widget.initialCompleted; // initial tab
  }

  @override
  void didUpdateWidget(covariant WorkItemsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCompleted != widget.initialCompleted) {
      setState(() {
        activeSelected = !widget.initialCompleted;
      });
    }
  }

  Future<List<WorkItem>> _load() {
    return AppDb.instance.listWorkItemsByStatus(activeSelected ? 'active' : 'completed');
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
              if (list.isEmpty) {
                return EmptyState(text: activeSelected ? "No active work items" : "No completed work items");
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _workCard(list[i], completed: !activeSelected),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _workCard(WorkItem it, {required bool completed}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
              child: Text(
                it.customerName,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              completed ? Icons.check_circle : Icons.timelapse,
              size: 18,
              color: completed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              completed ? "Completed" : "Active",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: completed ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(it.phone, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("\$${it.total.toStringAsFixed(2)}",
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
            if (completed)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ]),
    );
  }
}
