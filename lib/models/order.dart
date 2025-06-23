class Order {
  final int? id;
  final int userId;
  final DateTime orderDate;
  final double totalAmount;

  Order({
    this.id,
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
    };
  }

  static Order fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      orderDate: DateTime.parse(map['order_date']),
      totalAmount: map['total_amount'],
    );
  }
}