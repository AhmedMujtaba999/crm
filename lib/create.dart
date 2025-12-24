import 'package:crm/theme.dart';
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

enum CustomerExistsAction { cancel, openExisting, createNew }

class _CreateWorkItemPageState extends State<CreateWorkItemPage> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final addressC = TextEditingController();
  final notesC = TextEditingController();

  final amountC = TextEditingController();

  // If user selects "Create New" for an existing customer, we remember the phone
  // so the next Save will create the new work item without re-showing the dialog.
  String? _confirmedCreateForPhone;

  Future<CustomerExistsAction> showCustomerExistsDialog(BuildContext context, String phone, String email) async {
    final existing = await AppDb.instance.findLatestWorkItemByCustomer(phone: phone, email: email);

    final res = await showDialog<CustomerExistsAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Customer Already Exists", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ]),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // Show a small preview of the existing customer/work item to help the user decide
                if (existing != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEFEFEF))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(existing.customerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      if (existing.email.trim().isNotEmpty) Text(existing.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      if (existing.address.trim().isNotEmpty) Text(existing.address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                  ),

                const SizedBox(height: 12),
                const Text(
                  "A customer with this contact already exists. You can open their latest record or create a new work item with their basic details prefilled.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, CustomerExistsAction.cancel),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, CustomerExistsAction.openExisting),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFBFC7D8))),
                      child: const Text('Open Existing'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, CustomerExistsAction.createNew),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Create New', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ])
              ],
            ),
          ),
        );
      },
    );

    return res ?? CustomerExistsAction.cancel;
  }

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

    // Clear the confirmation when the phone changes so we don't accidentally
    // create for a different customer than the one the user confirmed.
    phoneC.addListener(() {
      final current = phoneC.text.trim();
      if (_confirmedCreateForPhone != null && current != _confirmedCreateForPhone) {
        setState(() => _confirmedCreateForPhone = null);
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

    // If the user already confirmed "Create New" for this phone, skip the dialog
    final skipDialog = (_confirmedCreateForPhone != null && _confirmedCreateForPhone == phone);

    if (exists && !skipDialog) {
      final action = await showCustomerExistsDialog(context, phone, email);
      if (action == CustomerExistsAction.cancel) return;

      if (action == CustomerExistsAction.openExisting) {
        // Open the most recent work item for this customer
        final existing = await AppDb.instance.findLatestWorkItemByCustomer(phone: phone, email: email);
        if (existing != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening existing work item')));
          Navigator.pushNamed(context, '/invoice', arguments: existing.id);
          return;
        }
        // If none found, fall-through and create new
      }

      if (action == CustomerExistsAction.createNew) {
        // Prefill basic details from the most recent customer record and let user confirm/save
        final existing = await AppDb.instance.findLatestWorkItemByCustomer(phone: phone, email: email);
        if (existing != null) {
          setState(() {
            if (nameC.text.trim().isEmpty) nameC.text = existing.customerName;
            if (phoneC.text.trim().isEmpty) phoneC.text = existing.phone;
            if (emailC.text.trim().isEmpty) emailC.text = existing.email;
            if (addressC.text.trim().isEmpty) addressC.text = existing.address;

            // Remember the user's intent so that the next Save will proceed
            _confirmedCreateForPhone = phone;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prefilled details from existing customer — review and tap Save to create new work item')));
          return; // stop here so user can review before creating
        }
        // If none found, just proceed to create
      }
    }

    // If user confirmed create new for this phone, proceed and then clear the flag
    if (_confirmedCreateForPhone != null && _confirmedCreateForPhone == phone) {
      _confirmedCreateForPhone = null; // consume it so next save is normal
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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