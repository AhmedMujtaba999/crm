class WorkItem {
  final String id;
  final String status; // 'active' | 'completed'
  final DateTime createdAt; // Activated date = createdAt
  final DateTime? completedAt; // Completed date
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final double total;

  final String? beforePhotoPath;
  final String? afterPhotoPath;

  

  WorkItem({
    required this.id,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    required this.total,
    this.beforePhotoPath,
    this.afterPhotoPath,
  });

    WorkItem copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? beforePhotoPath,
    String? afterPhotoPath,
  }) {
    return WorkItem(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes, 
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      beforePhotoPath: beforePhotoPath ?? this.beforePhotoPath,
      afterPhotoPath: afterPhotoPath ?? this.afterPhotoPath,
    );
  }


  Map<String, dynamic> toMap() => {
        'id': id,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'customerName': customerName,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'total': total,
        'beforePhotoPath': beforePhotoPath ?? "",
        'afterPhotoPath': afterPhotoPath ?? "",
      };

  static WorkItem fromMap(Map<String, dynamic> m) {
    DateTime? parseDT(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return WorkItem(
    
      id: (m['id'] ?? '').toString(),

      status: (m['status'] ?? 'active').toString(),
      createdAt: DateTime.parse(
        (m['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      ),
      completedAt: parseDT(m['completedAt']),
      customerName: (m['customerName'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      notes: (m['notes'] ?? '').toString(),
      total: (m['total'] is num)
          ? (m['total'] as num).toDouble()
          : double.tryParse((m['total'] ?? '0').toString()) ?? 0,
      beforePhotoPath:
          ((m['beforePhotoPath'] ?? '').toString().trim().isEmpty)
              ? null
              : m['beforePhotoPath'].toString(),
      afterPhotoPath:
          ((m['afterPhotoPath'] ?? '').toString().trim().isEmpty)
              ? null
              : m['afterPhotoPath'].toString(),
    );
  }
}

// =======================================================
// ServiceItem (UNCHANGED – string IDs are fine here)
// =======================================================
class ServiceItem {
  final String id;
  final String workItemId;
  final String name;
  final double amount;

  ServiceItem({
    required this.id,
    required this.workItemId,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'workItemId': workItemId,
        'name': name,
        'amount': amount,
      };

  static ServiceItem fromMap(Map<String, dynamic> m) => ServiceItem(
        id: (m['id'] ?? '').toString(),
        workItemId: (m['workItemId'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        amount: (m['amount'] is num)
            ? (m['amount'] as num).toDouble()
            : double.tryParse((m['amount'] ?? '0').toString()) ?? 0,
      );
}

// =======================================================
// TaskItem (UNCHANGED)
// =======================================================
class TaskItem {
  final String id;
  final String title;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;
  final DateTime scheduledAt;

  TaskItem({
    required this.id,
    required this.title,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.createdAt,
    required this.scheduledAt,
  });

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

  static TaskItem fromMap(Map<String, dynamic> m) => TaskItem(
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
      );
}
