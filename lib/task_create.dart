import 'package:crm/models/models.dart';
import 'package:crm/providers/task_provider.dart';
import 'package:crm/providers/work_items_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'widgets.dart';
import 'providers/task_create_provider.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  ServiceCatalogItem? selectedService;
  final amountC = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final customerNameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final titleC = TextEditingController();

  @override
  void dispose() {
    customerNameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    addressC.dispose();
    titleC.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TaskCreateProvider p) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: p.scheduledAt,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) p.setDate(picked);
  }

  Future<void> _save(TaskCreateProvider p) async {
    final ok = _formKey.currentState?.validate() ?? true;
    if (!ok) return;
    final success = await p.submit(
      customerName: customerNameC.text,
      phone: phoneC.text,
      email: emailC.text,
      address: addressC.text,
      title: titleC.text,
      context: context,
    );
    if (!mounted || !success) return;
await context.read<TasksProvider>().load();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Task created successfully")));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskCreateProvider>();

    final dateText = DateFormat('EEE, MMM d, y').format(provider.scheduledAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const GradientHeader(title: "Create Task", showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// ===== TASK DETAILS =====
                    _SectionCard(
                      title: "Task Details",
                      icon: Icons.assignment_outlined,
                      child: Column(
                        children: [
                          _DateSelector(
                            label: "Scheduled Date",
                            value: dateText,
                            onTap: () => _pickDate(provider),
                          ),
                          const SizedBox(height: 14),
                          CardBox(
                            title: " Select Services",
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      // 🔥 THIS IS THE FIX
                                      child: Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color.fromARGB(255, 43, 47, 54),
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<ServiceCatalogItem>(
                                            value: selectedService,
                                            isExpanded: true, // ✅ keep this
                                              menuMaxHeight: 300,
                                            hint: const Text("Select Service"),
                                            items: provider.servicesCatalog.map((
                                              service,
                                            ) {
                                              return DropdownMenuItem<
                                                ServiceCatalogItem
                                              >(
                                                value: service,
                                                child: Text(
                                                  service.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis, // ✅ important
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (service) {
                                              setState(() {
                                                selectedService = service;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 95,
                                      child: TextField(
                                        controller: amountC,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          hintText: "Amount",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // VALIDATIONS
                                          if (selectedService == null ||
                                              amountC.text.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Select service and enter amount",
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          context
                                              .read<TaskCreateProvider>()
                                              .addService(
                                                selectedService!,
                                                double.parse(amountC.text),
                                              );
                                          setState(() {
                                            selectedService =
                                                null; // ✅ RESET dropdown
                                          });
                                          amountC.clear();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2F5BFF,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                if (context
                                    .watch<TaskCreateProvider>()
                                    .services
                                    .isNotEmpty) ...[
                                  ...context
                                      .watch<TaskCreateProvider>()
                                      .services
                                      .map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: ServiceRow(
                                            name: s.name,
                                            amount: s.amount,
                                            onDelete: () => context
                                                .read<TaskCreateProvider>()
                                                .removeService(s),
                                          ),
                                        ),
                                      ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Amount",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        "\$${context.watch<TaskCreateProvider>().total.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2F5BFF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // _DropdownField(
                          //   value: null, // ✅ IMPORTANT
                          //   items: p.services,
                          //   onChanged: (value) {
                          //     if (value != null) {
                          //       p.addService(value);
                          //     }
                          //   },
                          //   hint: "Select Service",
                          // ),
                          // Wrap(
                          //   spacing: 8,
                          //   children: p.selectedServices.map((service) {
                          //     return Chip(
                          //       label: Text(service),
                          //       deleteIcon: const Icon(Icons.close),
                          //       onDeleted: () => p.removeService(service),
                          //     );
                          //   }).toList(),
                          // ),
                          const SizedBox(height: 14),

                          _TextField(
                            controller: titleC,
                            hint: "Task Title (optional)",
                            icon: Icons.edit_note,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ===== CUSTOMER DETAILS =====
                    _SectionCard(
                      title: "Customer Details",
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          _TextField(
                            controller: customerNameC,
                            hint: "Customer Name",
                            icon: Icons.person,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? "Customer name is required"
                                : null,
                          ),
                          const SizedBox(height: 12),

                          _TextField(
                            controller: phoneC,
                            hint: "Phone Number",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? "Phone is required"
                                : null,
                          ),
                          const SizedBox(height: 12),

                          _TextField(
                            controller: emailC,
                            hint: "Email (optional)",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 12),

                          _TextField(
                            controller: addressC,
                            hint: "Address (optional)",
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      /// ===== CTA =====
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: GradientButton(
          text: provider.saving ? "Creating..." : "Create Task",
          onTap: provider.saving ? null : () => _save(provider),
        ),
      ),
    );
  }
}

/// =======================
/// REUSABLE UI COMPONENTS
/// =======================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CardBox(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$label: $value",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged, // ✅ SAFE
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.build_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
