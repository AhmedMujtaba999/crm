import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'widgets.dart';
import 'theme.dart';
import 'providers/work_items_provider.dart';

class WorkItemsPage extends StatefulWidget {
  final String? initialTab; // 'active' or 'completed'
  const WorkItemsPage({super.key, this.initialTab});

  @override
  State<WorkItemsPage> createState() => _WorkItemsPageState();
}

class _WorkItemsPageState extends State<WorkItemsPage> {
  bool activeSelected = true;

  // Completed sub-tab
  bool completedByDateSelected = true;
  DateTime selectedDate = DateTime.now();


  @override
  void initState() {
    super.initState();
    

    if (widget.initialTab == 'completed') {
      activeSelected = false;
      completedByDateSelected = true;
      selectedDate = DateTime.now();
    }
    if (widget.initialTab == 'active') activeSelected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkItemsProvider>().load(
        active: activeSelected,
        byDate: completedByDateSelected,
        selectedDate: selectedDate,
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (_isSameDay(d, now)) return "Today";
    return DateFormat('EEE, MMM d, y').format(d);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;

    setState(() => selectedDate = picked);

    await context.read<WorkItemsProvider>().load(
      active: activeSelected,
      byDate: completedByDateSelected,
      selectedDate: selectedDate,
    );
  }

  Future<void> _openInvoice(WorkItem it) async {
    await Navigator.pushNamed(context, '/invoice', arguments: it.id);
    if (!mounted) return;

    await context.read<WorkItemsProvider>().load(
      active: activeSelected,
      byDate: completedByDateSelected,
      selectedDate: selectedDate,
    );
  }

  Future<void> _deleteWorkItem(WorkItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete work item?"),
        content: const Text(
          "This will permanently delete the work item and its services.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await context.read<WorkItemsProvider>().deleteItem(
      it.id.toString(),
    ); // deleting the completed work item using provider

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Deleted")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GradientHeader(
            title: "Work Items",
            child: PillSwitch(
              leftSelected: activeSelected,
              leftText: "Active",
              rightText: "Completed",
              onLeft: () {
                setState(() => activeSelected = true);
                context.read<WorkItemsProvider>().load(
                  active: true,
                  byDate: false,
                  selectedDate: selectedDate,
                );
              },
              onRight: () {
                setState(() {
                  activeSelected = false;
                  completedByDateSelected = true;
                  selectedDate = DateTime.now();
                });
                context.read<WorkItemsProvider>().load(
                  active: false,
                  byDate: true,
                  selectedDate: selectedDate,
                );
              },
            ),
          ),

          if (!activeSelected) _completedControls(),

          Expanded(
            child: Consumer<WorkItemsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = provider.items;

                if (list.isEmpty) {
                  final msg = activeSelected
                      ? "No active work items"
                      : completedByDateSelected
                      ? "No completed items for ${_dateLabel(selectedDate)}"
                      : "No completed work items";
                  return EmptyState(text: msg);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.load(
                      active: activeSelected,
                      byDate: completedByDateSelected,
                      selectedDate: selectedDate,
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _workCard(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // Completed Controls
  // =======================
  Widget _completedControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _segmentedTabs(),
            if (completedByDateSelected) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Showing: ${_dateLabel(selectedDate)}",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  // ✅ ADD THIS
                  IconButton(
                    icon: const Icon(Icons.calendar_month_sharp),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segmentedTabs() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 232, 232, 233),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => completedByDateSelected = true);
                context.read<WorkItemsProvider>().load(
                  active: false,
                  byDate: true,
                  selectedDate: selectedDate,
                );
              },
              child: Center(child: const Text("By date")),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => completedByDateSelected = false);
                context.read<WorkItemsProvider>().load(
                  active: false,
                  byDate: false,
                  selectedDate: selectedDate,
                );
              },
              child: Center(child: const Text("History")),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // Card
  // =======================
  Widget _workCard(WorkItem it) {
    return InkWell(
      onTap: () => _openInvoice(it),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 TOP ROW (Name + 3 dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    it.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ✅ 3 DOT MENU (ONLY FOR COMPLETED)
                if (!activeSelected)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteWorkItem(it);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 6),

            if (it.phone.trim().isNotEmpty)
              Text(it.phone, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "\$${it.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
