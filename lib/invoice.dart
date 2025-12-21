import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'storage.dart';
import 'widgets.dart';
import 'theme.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool attachPhotos = true;

  Future<(WorkItem, List<ServiceItem>)> load(String id) async {
    final items = await AppDb.instance.listWorkItems('active');
    final item = items.firstWhere((e) => e.id == id);
    final services = await AppDb.instance.listServices(id);
    return (item, services);
  }

  Future<void> pickPhoto(String workItemId, {required bool before}) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x == null) return;

    if (before) {
      await AppDb.instance.updatePhotos(workItemId: workItemId, beforePath: x.path);
    } else {
      await AppDb.instance.updatePhotos(workItemId: workItemId, afterPath: x.path);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final workItemId = (ModalRoute.of(context)?.settings.arguments ?? '') as String;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: "Invoice Preview", showBack: true),
          Expanded(
            child: FutureBuilder<(WorkItem, List<ServiceItem>)>(
              future: load(workItemId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final (item, services) = snap.data!;
                final dateText = DateFormat('EEEE, MMMM d, y').format(item.createdAt);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // invoice card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.description_outlined, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text("Work Item Invoice",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(dateText, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text("Customer Details", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(item.phone),
                            Text(item.email),
                            Text(item.address),
                            const Divider(height: 26),
                            const Text("Services", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...services.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text("\$${s.amount.toStringAsFixed(2)}"),
                                    ],
                                  ),
                                )),
                            const Divider(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text("\$${item.total.toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // photos section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: attachPhotos,
                                  onChanged: (v) => setState(() => attachPhotos = v ?? true),
                                ),
                                const Text("Attach Before/After Photos", style: TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                            if (attachPhotos) ...[
                              const SizedBox(height: 10),
                              _photoBox(
                                title: "Before Photo",
                                path: item.beforePhotoPath,
                                onTap: () => pickPhoto(workItemId, before: true),
                              ),
                              const SizedBox(height: 12),
                              _photoBox(
                                title: "After Photo",
                                path: item.afterPhotoPath,
                                onTap: () => pickPhoto(workItemId, before: false),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      PrimaryButton(
                        text: "Mark Completed",
                        icon: Icons.check_circle_outline,
                        onTap: () async {
                          await AppDb.instance.markCompleted(workItemId);
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox({required String title, required String? path, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.subText, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              color: AppColors.bg,
            ),
            child: path == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Capture Photo", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(path), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
}
