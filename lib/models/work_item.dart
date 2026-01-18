class WorkItem {
  final String id;
  final String status; // 'active' | 'completed'
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

  // ✅ NEW (frozen snapshot fields)
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

    // NEW
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

    // NEW
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

      // NEW
      attachPhotos: attachPhotos ?? this.attachPhotos,
      sendPhotosOnly: sendPhotosOnly ?? this.sendPhotosOnly,
      sendEmail: sendEmail ?? this.sendEmail,
      pdfPath: pdfPath ?? this.pdfPath,
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

        // NEW
        'attachPhotos': attachPhotos ? 1 : 0,
        'sendPhotosOnly': sendPhotosOnly ? 1 : 0,
        'sendEmail': sendEmail ? 1 : 0,
        'pdfPath': pdfPath ?? "",
      };

  static WorkItem fromMap(Map<String, dynamic> m) {
    DateTime? parseDT(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    

    bool parseBool(dynamic v) => v == 1 || v == true || v == '1';

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
          (m['beforePhotoPath']?.toString().trim().isEmpty ?? true)
              ? null
              : m['beforePhotoPath'].toString(),
      afterPhotoPath:
          (m['afterPhotoPath']?.toString().trim().isEmpty ?? true)
              ? null
              : m['afterPhotoPath'].toString(),

      // NEW
      attachPhotos: parseBool(m['attachPhotos']),
      sendPhotosOnly: parseBool(m['sendPhotosOnly']),
      sendEmail: parseBool(m['sendEmail']),
      pdfPath:
          (m['pdfPath']?.toString().trim().isEmpty ?? true)
              ? null
              : m['pdfPath'].toString(),
    );
  }
  
}
