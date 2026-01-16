import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crm/models/models.dart';

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
      version: 3, // ✅ bump version so migration runs
      onCreate: (db, _) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // ✅ Non-destructive migrations (no dropping tables)
        if (oldV < 3) {
          // work_items.completedAt
          try {
            await db.execute('ALTER TABLE work_items ADD COLUMN completedAt TEXT');
          } catch (_) {}

          // tasks.scheduledAt (in case DB was created before you added it)
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN scheduledAt TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE work_items (
        id TEXT PRIMARY KEY,
        status TEXT,
        createdAt TEXT,
        completedAt TEXT,
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
        createdAt TEXT,
        scheduledAt TEXT
      )
    ''');
  }

  // ---------------- Customer exists check ----------------
  Future<bool> customerExists({required String phone, required String email}) async {
    final rows = await db.query(
      'work_items',
      columns: ['id'],
      where: '(phone = ? AND phone != "") OR (email = ? AND email != "")',
      whereArgs: [phone, email],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String?> findLatestActiveWorkItemId({required String phone, required String email}) async {
    final rows = await db.query(
      'work_items',
      columns: ['id'],
      where: 'status = ? AND ((phone = ? AND phone != "") OR (email = ? AND email != ""))',
      whereArgs: ['active', phone, email],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  Future<WorkItem?> findLatestWorkItemByCustomer({required String phone, required String email}) async {
    final rows = await db.query(
      'work_items',
      where: '((phone = ? AND phone != "") OR (email = ? AND email != ""))',
      whereArgs: [phone, email],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return WorkItem.fromMap(rows.first);
  }

  // ---------------- Work Items ----------------
  Future<void> insertWorkItem(WorkItem item, List<ServiceItem> services) async {
    final d = db;

    await d.insert('work_items', item.toMap());
    for (final s in services) {
      await d.insert('services', s.toMap());
    }
  }

  Future<List<WorkItem>> listWorkItemsByStatus(String status) async {
    final order = (status == 'completed')
        ? 'completedAt DESC, createdAt DESC'
        : 'createdAt DESC';

    final rows = await db.query(
      'work_items',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: order,
    );

    return rows.map(WorkItem.fromMap).toList();
  }

  Future<WorkItem?> getWorkItem(String id) async {
    final rows = await db.query('work_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return WorkItem.fromMap(rows.first);
  }

  Future<List<ServiceItem>> listServices(String workItemId) async {
    final rows = await db.query('services', where: 'workItemId = ?', whereArgs: [workItemId]);
    return rows.map(ServiceItem.fromMap).toList();
  }

  Future<void> markCompleted(String workItemId) async {
    await db.update(
      'work_items',
      {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(), // ✅ save completed date
      },
      where: 'id = ?',
      whereArgs: [workItemId],
    );
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
  }

  Future<void> deleteWorkItem(String workItemId) async {
    // delete services first
    await db.delete('services', where: 'workItemId = ?', whereArgs: [workItemId]);
    // delete work item
    await db.delete('work_items', where: 'id = ?', whereArgs: [workItemId]);
  }

  // ---------------- Tasks ----------------
  Future<void> seedTasksIfEmpty() async {
    // keep your existing implementation (unchanged)
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks')) ?? 0;
    if (c > 0) return;

    final now = DateTime.now();

    final t1 = TaskItem(
      id: 't1',
      title: 'Pool Maintenance - Ahmed',
      customerName: 'Ahmed Hassan',
      phone: '9876543210',
      email: 'ahmed@email.com',
      address: '123 Main Street, Dubai',
      createdAt: DateTime(2024, 1, 15),
      scheduledAt: DateTime(now.year, now.month, now.day),
    );

    final t2 = TaskItem(
      id: 't2',
      title: 'Filter Service - Sameer',
      customerName: 'Sameer Khan',
      phone: '9123456780',
      email: 'sameer@email.com',
      address: '456 Beach Road, Abu Dhabi',
      createdAt: DateTime(2024, 1, 16),
      scheduledAt: DateTime(2024, 1, 16),
    );

    await db.insert('tasks', t1.toMap());
    await db.insert('tasks', t2.toMap());
  }

  Future<List<TaskItem>> listTasks({DateTime? forDate}) async {
    final rows = await db.query('tasks', orderBy: 'createdAt DESC');
    var list = rows.map(TaskItem.fromMap).toList();

    bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

    if (forDate != null) {
      final fd = DateTime(forDate.year, forDate.month, forDate.day);
      return list.where((t) => isSameDay(t.scheduledAt, fd)).toList();
    }

    // today first
    final today = DateTime.now();
    list.sort((a, b) {
      final aToday = isSameDay(a.scheduledAt, today);
      final bToday = isSameDay(b.scheduledAt, today);
      if (aToday && !bToday) return -1;
      if (bToday && !aToday) return 1;
      final cmp = b.scheduledAt.compareTo(a.scheduledAt);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return list;
  }

  Future<void> insertTask(TaskItem task) async {
    await db.insert('tasks', task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
