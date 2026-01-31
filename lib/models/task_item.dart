class TaskItem {
  final String id; // task id from backend
  final String title;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String status; // PENDING / ACTIVE / COMPLETED
  final DateTime scheduledAt; // backend: due_date
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

  static String _s(dynamic v, {String fallback = ""}) {
    if (v == null) return fallback;
    return v.toString();
    }

  static DateTime _dt(dynamic v) {
    final s = _s(v, fallback: "");
    final parsed = DateTime.tryParse(s);
    return parsed ?? DateTime.now();
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// ✅ API → MODEL (supports your old keys + the new backend response)
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // backend sends: due_date (NOT date)
    final scheduledRaw = json['due_date'] ?? json['date'] ?? json['scheduled_at'];

    final servicesRaw = (json['services'] is List) ? json['services'] as List : const [];

    return TaskItem(
      // backend sends: id
      id: _s(json['id'] ?? json['task_id']),

      // backend sends: title
      title: _s(json['title'] ?? json['task_title']),

      // backend sends: customer_name
      customerName: _s(json['customer_name'] ?? json['customerName']),

      phone: _s(json['phone']),
      email: _s(json['email']),

      // backend may not send address in your sample, so keep fallback
      address: _s(json['address']),

      status: _s(json['status']),

      scheduledAt: _dt(scheduledRaw),

      services: servicesRaw
          .map((s) => TaskServiceItem.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class TaskServiceItem {
  final String id; // service_id from backend
 // final String taskId; // not provided in your new response, keep empty
  final String name; // not provided in your new response, keep empty (or fill later by lookup)
  final double amount; // we map from unit_price (or total_price if you want)

  TaskServiceItem({
    required this.id,
   // required this.taskId,
    required this.name,
    required this.amount,
  });
  
  TaskServiceItem copyWith({String? name, double? amount}) => TaskServiceItem(
    id: id,
  //  taskId: taskId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
  );

  static String _s(dynamic v, {String fallback = ""}) {
    if (v == null) return fallback;
    return v.toString();
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory TaskServiceItem.fromJson(Map<String, dynamic> json) {
    return TaskServiceItem(
      // backend sends: service_id
      id: _s(json['service_id'] ?? json['id']),

      // backend response you showed does NOT include task_id inside services
      // taskId: _s(json['task_id']?? json['taskId'] ),

      // backend response you showed does NOT include service_name
      name: _s(json['service_name'] ?? json['name']),

      // backend sends: unit_price (you can change to total_price if needed)
      amount: _d(json['unit_price'] ?? json['total_price']),
    );
  }
}
