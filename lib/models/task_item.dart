class TaskItem {
  final String id; // task_id from backend
  final String title;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String status; // PENDING / ACTIVE / COMPLETED
  final DateTime scheduledAt;
  final List<TaskServiceItem> services;

  TaskItem({
    required this.id,
    required this.title,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
    required this.scheduledAt,
    required this.services,
  });

  /// ✅ API → MODEL
  factory TaskItem.fromJson(Map<String, dynamic> json) {
  return TaskItem(
    id: json['task_id'] ?? json['id'],
    title: json['task_title'] ?? '',
    customerName: json['customer_name'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    address: json['address'] ?? '',
    status: json['status'] ?? '',
    scheduledAt: DateTime.parse(json['date']),
    services: (json['services'] as List? ?? [])
        .map((s) => TaskServiceItem.fromJson(s))
        .toList(),
  );
  }
}
class TaskServiceItem {
  final String id;        // lead_service_id OR service mapping id// actual catalog service id
  final String taskId;
  final String name;
  final double amount;

  TaskServiceItem({
    required this.id,
    required this.taskId,
    required this.name,
    required this.amount,
  });
factory TaskServiceItem.fromJson(Map<String, dynamic> json) {
  return TaskServiceItem(
    id: json['id'] ?? '',
    taskId: json['task_id'] ?? '',
    name: json['service_name'] ?? '',
    amount: (json['unit_price'] as num).toDouble(),
  );
}}