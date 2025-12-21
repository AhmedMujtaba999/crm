import 'package:flutter/material.dart';
import 'models.dart';
import 'storage.dart';
import 'widgets.dart';
import 'theme.dart';

class CreateWorkItemPage extends StatefulWidget {
  final TaskItem? prefillTask; // 🔹 for task activation

  const CreateWorkItemPage({
    super.key,
    this.prefillTask,
  });

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

  final servicesList = const [
    'Water Change',
    'Filter Service',
    'Pool Cleaning',
    'Chemical Treatment',
    'Pump Check',
  ];

  String selectedService = 'Water Change';
  final List<ServiceItem> addedServices = [];

  @override
  void initState() {
    super.initState();

    // 🔹 PREFILL FROM TASK (when activated from Tasks screen)
    final t = widget.prefillTask;
    if (t != null) {
      nameC.text = t.customerName;
      phoneC.text = t.phone;
      emailC.text = t.email;
      addressC.text = t.address;
    }
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

  double get total =>
      addedServices.fold(0.0, (sum, s) => sum + s.amount);

  void addService() {
    final amt = double.tryParse(amountC.text.trim());
    if (amt == null || amt <= 0) return;

    setState(() {
      addedServices.add(ServiceItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        workItemId: 'temp',
        name: selectedService,
        amount: amt,
      ));
      amountC.clear();
    });
  }

  Future<void> saveWorkItem() async {
    if (nameC.text.trim().isEmpty || addedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name & service required')),
      );
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final item = WorkItem(
      id: id,
      status: 'active',
      createdAt: DateTime.now(),
      customerName: nameC.text.trim(),
      phone: phoneC.text.trim(),
      email: emailC.text.trim(),
      address: addressC.text.trim(),
      notes: notesC.text.trim(),
      total: total,
    );

    final services = addedServices
        .map((s) => ServiceItem(
              id: s.id,
              workItemId: id,
              name: s.name,
              amount: s.amount,
            ))
        .toList();

    await AppDb.instance.insertWorkItem(item, services);

    if (!mounted) return;
    Navigator.pushNamed(context, '/invoice', arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          title: "Create Work Item",
          showBack: widget.prefillTask != null,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              /// ---------------- CUSTOMER DETAILS ----------------
              _card(
                title: "Customer Details",
                child: Column(children: [
                  AppTextField(
                    label: "Customer Name",
                    hint: "Enter customer name",
                    icon: Icons.person_outline,
                    controller: nameC,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Phone Number",
                    hint: "Enter phone number",
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    controller: phoneC,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Email",
                    hint: "Enter email address",
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    controller: emailC,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Address",
                    hint: "Enter address",
                    icon: Icons.location_on_outlined,
                    controller: addressC,
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              /// ---------------- SERVICES ----------------
              _card(
                title: "Services",
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: _dropdown(),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: amountC,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Amount"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _addButton(),
                  ]),

                  const SizedBox(height: 12),

                  ...addedServices.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ServiceRow(
                          name: s.name,
                          amount: s.amount,
                          onDelete: () =>
                              setState(() => addedServices.remove(s)),
                        ),
                      )),

                  if (addedServices.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount",
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text("\$${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                      ],
                    ),
                  ]
                ]),
              ),

              const SizedBox(height: 16),

              /// ---------------- NOTES ----------------
              _card(
                title: "Notes (Optional)",
                child: TextField(
                  controller: notesC,
                  maxLines: 4,
                  decoration: _inputDecoration(
                      "Add any additional notes or remarks..."),
                ),
              ),

              const SizedBox(height: 18),
              PrimaryButton(
                text: "Save Work Item",
                onTap: saveWorkItem,
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /// ---------------- HELPERS ----------------

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedService,
          isExpanded: true,
          items: servicesList
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) =>
              setState(() => selectedService = v ?? selectedService),
        ),
      ),
    );
  }

  Widget _addButton() {
    return SizedBox(
      width: 54,
      height: 54,
      child: ElevatedButton(
        onPressed: addService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
