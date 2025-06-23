import 'package:flutter/material.dart';
import '../models/product.dart';
import '../helpers/database_helper.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    _products = await _dbHelper.getProducts();
    notifyListeners();
  }
}