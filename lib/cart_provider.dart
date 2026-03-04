import 'package:flutter/material.dart';
import 'product.dart';
import 'database_helper.dart';

class CartItemModel {
  final Product product;
  int quantity;

  CartItemModel({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  bool _isLoading = true;

  List<CartItemModel> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  bool get isLoading => _isLoading;

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    final cartItems = await DatabaseHelper.instance.getCartItems();
    final products = await DatabaseHelper.instance.getProducts();

    _items.clear();

    for (final cartItem in cartItems) {
      final productId = cartItem['productId'] as int;
      final quantity = cartItem['quantity'] as int;

      final productData = products.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => {},
      );

      if (productData.isNotEmpty) {
        _items.add(
          CartItemModel(
            product: Product.fromMap(productData),
            quantity: quantity,
          ),
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
      await DatabaseHelper.instance.updateCartItemQuantity(
        product.id!,
        _items[existingIndex].quantity,
      );
    } else {
      _items.add(CartItemModel(product: product));
      await DatabaseHelper.instance.insertCartItem(product.id!, 1);
    }
    notifyListeners();
  }

  Future<void> removeProduct(int productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    await DatabaseHelper.instance.removeCartItem(productId);
    notifyListeners();
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await removeProduct(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      await DatabaseHelper.instance.updateCartItemQuantity(productId, quantity);
      notifyListeners();
    }
  }

  Future<void> incrementQuantity(int productId) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      await DatabaseHelper.instance.updateCartItemQuantity(
        productId,
        _items[index].quantity,
      );
      notifyListeners();
    }
  }

  Future<void> decrementQuantity(int productId) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        await DatabaseHelper.instance.updateCartItemQuantity(
          productId,
          _items[index].quantity,
        );
      } else {
        _items.removeAt(index);
        await DatabaseHelper.instance.removeCartItem(productId);
      }
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _items.clear();
    await DatabaseHelper.instance.clearCart();
    notifyListeners();
  }

  bool containsProduct(int productId) {
    return _items.any((item) => item.product.id == productId);
  }
}
