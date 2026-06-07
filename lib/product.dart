class Product {
  final String? id;
  final String image;
  final String title;
  final String price;
  final String unit;
  final String description;
  final String longDescription;
  final String? category;
  final String? season;
  final String? farmerUid;
  final String? farmName;

  Product({
    this.id,
    required this.image,
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
    required this.longDescription,
    this.category,
    this.season,
    this.farmerUid,
    this.farmName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'price': price,
      'unit': unit,
      'description': description,
      'longDescription': longDescription,
      'category': category,
      'season': season,
      'farmerUid': farmerUid,
      'farmName': farmName,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Product(
      id: docId ?? map['id'],
      image: map['image'] ?? map['imageUrl'] ?? map['imagePath'] ?? '',
      title: map['title'] ?? map['name'] ?? '',
      price: map['price']?.toString() ?? '0',
      unit: map['unit'] ?? '',
      description: map['description'] ?? '',
      longDescription: map['longDescription'] ?? map['description'] ?? '',
      category: map['category'],
      season: map['season'],
      farmerUid: map['farmerUid'],
      farmName: map['farmName'],
    );
  }
}
