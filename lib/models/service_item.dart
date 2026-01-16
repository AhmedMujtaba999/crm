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
