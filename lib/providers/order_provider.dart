import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../helpers/database_helper.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  Future<bool> submitOrder({
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
  }) async {
    try {
      // Insert user
      User user = User(
        name: name,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
      );
      int userId = await _dbHelper.insertUser(user);

      // Insert order
      Order order = Order(
        userId: userId,
        orderDate: DateTime.now(),
        totalAmount: totalAmount,
      );
      int orderId = await _dbHelper.insertOrder(order);

      // Insert order items
      for (var item in cartItems) {
        OrderItem orderItem = OrderItem(
          orderId: orderId,
          productId: item['product'].id,
          quantity: item['quantity'],
          price: item['product'].price,
        );
        await _dbHelper.insertOrderItem(orderItem);
      }

      await loadOrders();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadOrders() async {
    _orders = await _dbHelper.getOrdersWithDetails();
    notifyListeners();
  }
}