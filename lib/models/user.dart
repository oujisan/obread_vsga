class User {
  final int? id;
  final String name;
  final String phone;
  final double latitude;
  final double longitude;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}