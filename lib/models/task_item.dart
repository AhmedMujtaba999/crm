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
