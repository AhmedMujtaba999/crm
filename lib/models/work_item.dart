class WorkItem {
  final String id;
  final String status; // active | completed
  final DateTime createdAt;
  final DateTime? completedAt;

  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final double total;

  final String? beforePhotoPath;
  final String? afterPhotoPath;

  final bool attachPhotos;
  final bool sendPhotosOnly;
  final bool sendEmail;
  final String? pdfPath;

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
    this.attachPhotos = false,
    this.sendPhotosOnly = false,
    this.sendEmail = false,
    this.pdfPath,
  });
WorkItem copyWith({
  String? id,
  String? status,
  DateTime? createdAt,
  DateTime? completedAt,
  String? customerName,
  String? phone,
  String? email,
  String? address,
  String? notes,
  double? total,
  String? beforePhotoPath,
  String? afterPhotoPath,
  bool? attachPhotos,
  bool? sendPhotosOnly,
  bool? sendEmail,
  String? pdfPath,
}) {
  return WorkItem(
    id: id ?? this.id,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
    customerName: customerName ?? this.customerName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    total: total ?? this.total,
    beforePhotoPath: beforePhotoPath ?? this.beforePhotoPath,
    afterPhotoPath: afterPhotoPath ?? this.afterPhotoPath,
    attachPhotos: attachPhotos ?? this.attachPhotos,
    sendPhotosOnly: sendPhotosOnly ?? this.sendPhotosOnly,
    sendEmail: sendEmail ?? this.sendEmail,
    pdfPath: pdfPath ?? this.pdfPath,
  );
}

  // =========================
  // 🔴 LOCAL DB (UNCHANGED)
  // =========================
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
        'attachPhotos': attachPhotos ? 1 : 0,
        'sendPhotosOnly': sendPhotosOnly ? 1 : 0,
        'sendEmail': sendEmail ? 1 : 0,
        'pdfPath': pdfPath ?? "",
      };

  static WorkItem fromMap(Map<String, dynamic> m) {
    DateTime? parseDT(dynamic v) {
      if (v == null || v.toString().isEmpty) return null;
      return DateTime.tryParse(v.toString());
    }

    bool parseBool(dynamic v) => v == 1 || v == true || v == '1';

    return WorkItem(
      id: (m['id'] ?? '').toString(),
      status: (m['status'] ?? 'active').toString(),
      createdAt: DateTime.parse(m['createdAt']),
      completedAt: parseDT(m['completedAt']),
      customerName: m['customerName'] ?? '',
      phone: m['phone'] ?? '',
      email: m['email'] ?? '',
      address: m['address'] ?? '',
      notes: m['notes'] ?? '',
      total: (m['total'] as num).toDouble(),
      beforePhotoPath: m['beforePhotoPath'],
      afterPhotoPath: m['afterPhotoPath'],
      attachPhotos: parseBool(m['attachPhotos']),
      sendPhotosOnly: parseBool(m['sendPhotosOnly']),
      sendEmail: parseBool(m['sendEmail']),
      pdfPath: m['pdfPath'],
    );
  }

  // =========================
  // 🔥 NEW — API JSON SUPPORT
  // =========================
  factory WorkItem.fromJson(Map<String, dynamic> json) {
    double total = 0;

    if (json['services'] is List) {
      for (final s in json['services']) {
        final qty = (s['quantity'] ?? 1) as num;
        final price = (s['unit_price'] ?? 0) as num;
        total += qty * price;
      }
    }

    return WorkItem(
      id: (json['task_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'ACTIVE').toString().toLowerCase(),
      createdAt:
          DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      completedAt: null,
      customerName: json['customer_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      notes: json['description'] ?? '',
      total: total,
      beforePhotoPath: null,
      afterPhotoPath: null,
      attachPhotos: false,
      sendPhotosOnly: false,
      sendEmail: false,
      pdfPath: null,
    );
  }
}
