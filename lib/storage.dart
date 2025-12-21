import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDb {
  AppDb._();
  static final instance = AppDb._();

  Database? _db;

  Database get db {
    if (_db == null) throw Exception('DB not initialized');
    return _db!;
  }

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'poolpro_crm.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE work_items (
            id TEXT PRIMARY KEY,
            status TEXT,
            createdAt TEXT,
            customerName TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            notes TEXT,
            total REAL,
            beforePhotoPath TEXT,
            afterPhotoPath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE services (
            id TEXT PRIMARY KEY,
            workItemId TEXT,
            name TEXT,
            amount REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT,
            customerName TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  // ---------------- Work Items ----------------

  Future<void> insertWorkItem(WorkItem item, List<ServiceItem> services) async {
    final d = db;

    await d.insert('work_items', item.toMap());
    for (final s in services) {
      await d.insert('services', s.toMap());
    }

    // TODO BACKEND (Node.js):
    // POST /work-items (item + services)
  }

  Future<List<WorkItem>> listWorkItems(String status) async {
    final rows = await db.query(
      'work_items',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return rows.map(WorkItem.fromMap).toList();
  }

  Future<List<ServiceItem>> listServices(String workItemId) async {
    final rows = await db.query(
      'services',
      where: 'workItemId = ?',
      whereArgs: [workItemId],
    );
    return rows.map(ServiceItem.fromMap).toList();
  }

  Future<void> markCompleted(String id) async {
    await db.update('work_items', {'status': 'completed'}, where: 'id = ?', whereArgs: [id]);

    // TODO BACKEND (Node.js):
    // PATCH /work-items/:id  {status: "completed"}
  }

  Future<void> updatePhotos({
    required String workItemId,
    String? beforePath,
    String? afterPath,
  }) async {
    final data = <String, dynamic>{};
    if (beforePath != null) data['beforePhotoPath'] = beforePath;
    if (afterPath != null) data['afterPhotoPath'] = afterPath;

    await db.update('work_items', data, where: 'id = ?', whereArgs: [workItemId]);

    // TODO BACKEND (Node.js):
    // POST /work-items/:id/photos
  }

  // ---------------- Tasks ----------------

  Future<void> seedTasksIfEmpty() async {
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks')) ?? 0;
    if (c > 0) return;

    final t1 = TaskItem(
      id: 't1',
      title: 'Pool Maintenance - Ahmed',
      customerName: 'Ahmed Hassan',
      phone: '9876543210',
      email: 'ahmed@email.com',
      address: '123 Main Street, Dubai',
      createdAt: DateTime(2024, 1, 15),
    );

    final t2 = TaskItem(
      id: 't2',
      title: 'Filter Service - Sameer',
      customerName: 'Sameer Khan',
      phone: '9123456780',
      email: 'sameer@email.com',
      address: '456 Beach Road, Abu Dhabi',
      createdAt: DateTime(2024, 1, 16),
    );

    await db.insert('tasks', t1.toMap());
    await db.insert('tasks', t2.toMap());
  }

  Future<List<TaskItem>> listTasks() async {
    final rows = await db.query('tasks', orderBy: 'createdAt DESC');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<void> deleteTask(String id) async {
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);

    // TODO BACKEND (Node.js):
    // DELETE /tasks/:id
  }
}
