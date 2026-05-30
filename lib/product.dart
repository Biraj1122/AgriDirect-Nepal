class Product {
  final String image;
  final String title;
  final String price;
  final String unit;
  final String description;
  final String longDescription;

  Product({
    required this.image,
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
    required this.longDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'title': title,
      'price': price,
      'unit': unit,
      'description': description,
      'longDescription': longDescription,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      image: map['image'] ?? '',
      title: map['title'] ?? '',
      price: map['price']?.toString() ?? '0',
      unit: map['unit'] ?? '',
      description: map['description'] ?? '',
      longDescription: map['longDescription'] ?? '',
    );
  }
}
