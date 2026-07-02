import '../config/aws_config.dart';

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
  final double? farmerLat;
  final double? farmerLng;

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
    this.farmerLat,
    this.farmerLng,
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
      'farmerLat': farmerLat,
      'farmerLng': farmerLng,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Prefer s3Url, then imageUrl, then image, then imagePath
    String imageVal = map['imageUrl'] ?? map['image'] ?? map['s3Url'] ?? map['imagePath'] ?? '';
    
    // If the image is just a key/filename and NOT a network URL, get the full AWS URL if possible
    if (imageVal.isNotEmpty && 
        !imageVal.startsWith('http') && 
        !imageVal.startsWith('assets/') && 
        !imageVal.startsWith('data:image')) {
      // Fallback check: if it contains a dot but no slash, it might be an asset name we now want to handle as network if seeded
      // For now, let's trust the seeder gives full URLs. 
      // But for backward compatibility with AWS:
      imageVal = AWSConfig.getImageUrl(imageVal);
    }
    
    return Product(
      id: docId ?? map['id'],
      image: imageVal,
      title: map['title'] ?? map['name'] ?? '',
      price: map['price']?.toString() ?? '0',
      unit: map['unit'] ?? '',
      description: map['description'] ?? '',
      longDescription: map['longDescription'] ?? map['description'] ?? '',
      category: map['category'],
      season: map['season'],
      farmerUid: map['farmerUid'],
      farmName: map['farmName'],
      farmerLat: (map['farmerLat'] as num?)?.toDouble(),
      farmerLng: (map['farmerLng'] as num?)?.toDouble(),
    );
  }
}
