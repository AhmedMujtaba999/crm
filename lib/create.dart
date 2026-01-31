import 'package:crm/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm/models/models.dart';
import 'widgets.dart';
import 'package:provider/provider.dart';
import 'providers/create_work_item_provider.dart';

class CreateWorkItemPage extends StatefulWidget {
  final TaskItem? prefillTask;
  const CreateWorkItemPage({super.key, this.prefillTask});
  @override
  State<CreateWorkItemPage> createState() => _CreateWorkItemPageState();
}
class _CreateWorkItemPageState extends State<CreateWorkItemPage> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final notesC = TextEditingController();
  final amountC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  /// 🔧 CHANGED: selected service is an OBJECT
  ServiceCatalogItem? selectedService;
  @override
  void initState() {
    super.initState();
    // Prefill text fields immediately
    final t = widget.prefillTask;
    if (t != null) {
      nameC.text = t.customerName;
      phoneC.text = t.phone;
      emailC.text = t.email;
      addressC.text = t.address;
      // notesC.text = t.; // only if TaskItem has notes field
    }
    // Load catalog, THEN prefill provider services
    Future.microtask(() async {
      if (!mounted) return;
      final provider = context.read<CreateWorkItemProvider>();
      await provider.loadServiceCatalog();
      if (!mounted) return;
      if (widget.prefillTask != null) {
        provider.prefillFromTask(widget.prefillTask!);
      } else {
        provider.clearDraft(); // prevents old services from previous draft
      }
    });
  }
  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    addressC.dispose();
    notesC.dispose();
    amountC.dispose();
    super.dispose();
  }
  void _addService() {
    final provider = context.read<CreateWorkItemProvider>();
    final amount = double.tryParse(amountC.text);

    /// 🔧 CHANGED: proper validation
    if (selectedService == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select service and valid amount")),
      );
      return;
    }
    provider.addService(selectedService!, amount);
    /// 🔧 reset inputs
    setState(() => selectedService = null);
    amountC.clear();
  }
  Future<void> _save() async {
    final provider = context.read<CreateWorkItemProvider>();
    // 1️⃣ Validate form
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // 2️⃣ Ensure services exist
    if (provider.services.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one service")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      // 3️⃣ Call API
      final response = await provider.save(
        customerName: nameC.text.trim(),
        phone: phoneC.text.trim(),
        email: emailC.text.trim(),
        address: addressC.text.trim(),
        notes: notesC.text.trim(),
      );
      // 4️⃣ SAFETY CHECK
      if (!mounted) return;
      // 5️⃣ SHOW SUCCESS MESSAGE ✅
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      // 6️⃣ GO TO HOME (Active tab) ✅
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {'tab': 1, 'workTab': 'active'},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateWorkItemProvider>();
    final services = provider.services;
    final catalog = provider.serviceCatalog;
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: "Create Work Item"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// CUSTOMER DETAILS
                  CardBox(
                    title: "Customer Details",
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _input("Customer Name", nameC),
                          _input(
                            "Phone",
                            phoneC,
                            keyboard: TextInputType.phone,
                          ),
                          _input(
                            "Email",
                            emailC,
                            keyboard: TextInputType.emailAddress,
                          ),
                          _input("Address", addressC),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  /// 🔧 SERVICES
                  CardBox(
                    title: "Services",
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  DropdownButtonFormField<ServiceCatalogItem>(
                                    value: selectedService,
                                    hint: const Text("Select service"),
                                    items: catalog
                                        .map(
                                          (s) =>
                                              DropdownMenuItem<
                                                ServiceCatalogItem
                                              >(value: s, child: Text(s.name)),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => selectedService = v),
                                  ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: amountC,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  hintText: "Amount",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addService,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...services.map(
                          (s) => ServiceRow(
                            name: s.name,
                            amount: s.amount,
                            onDelete: () => provider.removeService(s),
                          ),
                        ),
                        if (services.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            "Total: \$${provider.total.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CardBox(
                    title: "Notes",
                    child: TextField(
                      controller: notesC,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Optional notes",
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GradientButton(
                    text: _isSaving ? "Saving..." : "Save Work Item",
                    onTap: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? "$label required" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
