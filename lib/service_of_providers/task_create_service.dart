import 'package:uuid/uuid.dart';
import '../models.dart';
import '../storage.dart';

class TaskCreateService {
  Future<void> createTask({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String title,
    required DateTime scheduledAt,
  }) async {
    final id = const Uuid().v4();

    final task = TaskItem(
      id: id,
      title: title,
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      createdAt: DateTime.now(), // real creation time
      scheduledAt: scheduledAt, // calendar date
    );

    await AppDb.instance.insertTask(task);
  }
}
