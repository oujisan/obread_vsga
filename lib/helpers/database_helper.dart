import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bakery_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Insert sample products
    await db.insert('products', {'name': 'Roti Tawar', 'price': 15000, 'type': 'roti'});
    await db.insert('products', {'name': 'Roti Coklat', 'price': 18000, 'type': 'roti'});
    await db.insert('products', {'name': 'Roti Keju', 'price': 20000, 'type': 'roti'});
    await db.insert('products', {'name': 'Kue Ulang Tahun', 'price': 150000, 'type': 'kue'});
    await db.insert('products', {'name': 'Kue Coklat', 'price': 75000, 'type': 'kue'});
    await db.insert('products', {'name': 'Kue Vanilla', 'price': 65000, 'type': 'kue'});
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Product operations
  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Order operations
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<int> insertOrderItem(OrderItem orderItem) async {
    final db = await database;
    return await db.insert('order_items', orderItem.toMap());
  }

  Future<List<Map<String, dynamic>>> getOrdersWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        o.id as order_id,
        o.order_date,
        o.total_amount,
        u.name as user_name,
        u.phone as user_phone,
        u.latitude,
        u.longitude,
        GROUP_CONCAT(p.name || ' x' || oi.quantity) as items
      FROM orders o
      JOIN users u ON o.user_id = u.id
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      GROUP BY o.id
      ORDER BY o.order_date DESC
    ''');
  }
}