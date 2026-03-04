import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    await _ensureCartTableExists(_database!);
    return _database!;
  }

  Future<void> _ensureCartTableExists(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          quantity INTEGER,
          addedAt TEXT,
          FOREIGN KEY (productId) REFERENCES products (id)
        )
      ''');
    } catch (e) {
      // Table might already exist
    }
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'checkout.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          quantity INTEGER,
          addedAt TEXT,
          FOREIGN KEY (productId) REFERENCES products (id)
        )
      ''');

      final existingProducts = await db.query('products');
      if (existingProducts.isEmpty) {
        await _insertInitialProducts(db);
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          quantity INTEGER,
          addedAt TEXT,
          FOREIGN KEY (productId) REFERENCES products (id)
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardHolder TEXT,
        cardNumber TEXT,
        validUntil TEXT,
        cvv TEXT,
        paymentMethod TEXT,
        promoCode TEXT,
        totalPrice REAL,
        saveCard INTEGER,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardHolder TEXT,
        cardNumber TEXT,
        validUntil TEXT,
        paymentMethod TEXT,
        lastUsed TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        quantity INTEGER,
        addedAt TEXT,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await _insertInitialProducts(db);
  }

  Future<void> _insertInitialProducts(Database db) async {
    final products = [
      {
        'name': 'Wireless Headphones',
        'description':
            'High-quality wireless headphones with noise cancellation',
        'price': 149.99,
        'imageUrl': 'headphones',
        'category': 'Electronics',
      },
      {
        'name': 'Smart Watch',
        'description': 'Fitness tracker with heart rate monitor',
        'price': 299.99,
        'imageUrl': 'watch',
        'category': 'Electronics',
      },
      {
        'name': 'Running Shoes',
        'description': 'Comfortable running shoes for daily workouts',
        'price': 89.99,
        'imageUrl': 'shoes',
        'category': 'Sports',
      },
      {
        'name': 'Laptop Stand',
        'description': 'Ergonomic aluminum laptop stand',
        'price': 49.99,
        'imageUrl': 'stand',
        'category': 'Accessories',
      },
      {
        'name': 'Bluetooth Speaker',
        'description': 'Portable speaker with 20h battery life',
        'price': 79.99,
        'imageUrl': 'speaker',
        'category': 'Electronics',
      },
      {
        'name': 'Yoga Mat',
        'description': 'Non-slip premium yoga mat',
        'price': 34.99,
        'imageUrl': 'mat',
        'category': 'Sports',
      },
      {
        'name': 'USB-C Hub',
        'description': '7-in-1 USB-C hub with HDMI',
        'price': 59.99,
        'imageUrl': 'hub',
        'category': 'Accessories',
      },
      {
        'name': 'Water Bottle',
        'description': 'Insulated stainless steel water bottle',
        'price': 24.99,
        'imageUrl': 'bottle',
        'category': 'Sports',
      },
    ];

    for (final product in products) {
      await db.insert('products', product);
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'createdAt DESC');
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertSavedCard(Map<String, dynamic> card) async {
    final db = await database;
    return await db.insert('saved_cards', card);
  }

  Future<List<Map<String, dynamic>>> getSavedCards() async {
    final db = await database;
    return await db.query('saved_cards', orderBy: 'lastUsed DESC');
  }

  Future<int> deleteSavedCard(int id) async {
    final db = await database;
    return await db.delete('saved_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCardLastUsed(int id) async {
    final db = await database;
    await db.update(
      'saved_cards',
      {'lastUsed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCartItem(int productId, int quantity) async {
    final db = await database;
    final existing = await db.query(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {'quantity': currentQty + quantity},
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return existing.first['id'] as int;
    }
    return await db.insert('cart_items', {
      'productId': productId,
      'quantity': quantity,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return await db.query('cart_items');
  }

  Future<void> updateCartItemQuantity(int productId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete(
        'cart_items',
        where: 'productId = ?',
        whereArgs: [productId],
      );
    } else {
      await db.update(
        'cart_items',
        {'quantity': quantity},
        where: 'productId = ?',
        whereArgs: [productId],
      );
    }
  }

  Future<void> removeCartItem(int productId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
  }
}
