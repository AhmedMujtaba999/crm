class ServiceItem {
  final String serviceid;
//  final String workItemId;
  final String name;
  final double amount;

  ServiceItem({
    required this.serviceid,
 //   required this.workItemId,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'serviceid': serviceid,
    //    'workItemId': workItemId,
        'name': name,
        'amount': amount,
      };

  static ServiceItem fromMap(Map<String, dynamic> m) => ServiceItem(
        serviceid: (m['serviceid'] ?? '').toString(),
   //     workItemId: (m['workItemId'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        amount: (m['amount'] is num)
            ? (m['amount'] as num).toDouble()
            : double.tryParse((m['amount'] ?? '0').toString()) ?? 0,
      );
}
