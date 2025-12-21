import 'package:flutter/material.dart';
import 'models.dart';
import 'storage.dart';
import 'widgets.dart';

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

  final demoServices = const [
    'Select service',
    'Water Change',
    'Filter Service',
    'Pool Cleaning',
    'Chemical Treatment',
  ];

  String selectedService = 'Select service';
  final List<ServiceItem> services = [];

  double get total => services.fold(0.0, (p, e) => p + e.amount);

  @override
  void initState() {
    super.initState();
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

  void addService() {
    final amt = double.tryParse(amountC.text.trim());
    if (selectedService == 'Select service') return;
    if (amt == null || amt <= 0) return;

    setState(() {
      services.add(ServiceItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        workItemId: 'temp',
        name: selectedService,
        amount: amt,
      ));
      amountC.clear();
      selectedService = 'Select service';
    });
  }

  Future<void> saveWorkItem() async {
    final name = nameC.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer name is required")));
      return;
    }
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one service")));
      return;
    }

    final phone = phoneC.text.trim();
    final email = emailC.text.trim();

    final exists = await AppDb.instance.customerExists(phone: phone, email: email);
    if (exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer exists")));
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final item = WorkItem(
      id: id,
      status: 'active',
      createdAt: DateTime.now(),
      customerName: name,
      phone: phone,
      email: email,
      address: addressC.text.trim(),
      notes: notesC.text.trim(),
      total: total,
    );

    final mapped = services
        .map((s) => ServiceItem(
              id: s.id,
              workItemId: id,
              name: s.name,
              amount: s.amount,
            ))
        .toList();

    await AppDb.instance.insertWorkItem(item, mapped);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Work item created")));
    Navigator.pushNamed(context, '/invoice', arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const GradientHeader(title: "Create Work Item"),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              CardBox(
                title: "Customer Details",
                child: Column(children: [
                  AppTextField(label: "Customer Name", hint: "Enter customer name", icon: Icons.person_outline, controller: nameC),
                  const SizedBox(height: 12),
                  AppTextField(label: "Phone Number", hint: "Enter phone number", icon: Icons.phone_outlined, controller: phoneC, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  AppTextField(label: "Email", hint: "Enter email address", icon: Icons.email_outlined, controller: emailC, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  AppTextField(label: "Address", hint: "Enter address", icon: Icons.location_on_outlined, controller: addressC),
                ]),
              ),

              const SizedBox(height: 14),

              CardBox(
                title: "Services",
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedService,
                            isExpanded: true,
                            items: demoServices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => selectedService = v ?? selectedService),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 95,
                      child: TextField(
                        controller: amountC,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Amount",
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF2F5BFF)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: addService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5BFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (services.isNotEmpty) ...[
                    ...services.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ServiceRow(
                            name: s.name,
                            amount: s.amount,
                            onDelete: () => setState(() => services.remove(s)),
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w900)),
                        Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2F5BFF))),
                      ],
                    ),
                  ],
                ]),
              ),

              const SizedBox(height: 14),

              CardBox(
                title: "Notes (Optional)",
                child: TextField(
                  controller: notesC,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Add any additional notes or remarks...",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2F5BFF)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              GradientButton(text: "Save Work Item", onTap: saveWorkItem),
            ]),
          ),
        ),
      ]),
    );
  }
}