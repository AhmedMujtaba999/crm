class TaskItem {
  final String id;
  final String title;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final List<TaskServiceItem> services;

  TaskItem({
    required this.id,
    required this.title,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.createdAt,
    required this.scheduledAt,
    required this.services,
  });

  /// Map of task fields only (no services) for DB storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'customerName': customerName,
    'phone': phone,
    'email': email,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
    'scheduledAt': scheduledAt.toIso8601String(),
  };

  static TaskItem fromMap(
    Map<String, dynamic> m, {
    List<TaskServiceItem> services = const [],
  }) => TaskItem(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    customerName: (m['customerName'] ?? '').toString(),
    phone: (m['phone'] ?? '').toString(),
    email: (m['email'] ?? '').toString(),
    address: (m['address'] ?? '').toString(),
    createdAt: DateTime.parse(
      (m['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
    ),
    scheduledAt: DateTime.parse(
      (m['scheduledAt'] ?? DateTime.now().toIso8601String()).toString(),
    ),
    services: services,
  );
}

class TaskServiceItem {
  final String id;
  final String taskId;
  final String name;
  final double amount;

  const TaskServiceItem({
    this.id = '',
    this.taskId = '',
    required this.name,
    required this.amount,
  });

  TaskServiceItem copyWith({
    String? id,
    String? taskId,
    String? name,
    double? amount,
  }) => TaskServiceItem(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'name': name,
    'amount': amount,
  };

  static TaskServiceItem fromMap(Map<String, dynamic> m) => TaskServiceItem(
    id: (m['id'] ?? '').toString(),
    taskId: (m['taskId'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    amount: (m['amount'] is num)
        ? (m['amount'] as num).toDouble()
        : double.tryParse((m['amount'] ?? '0').toString()) ?? 0,
  );
}
