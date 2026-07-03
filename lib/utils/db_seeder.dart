import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Seeds the database with comprehensive Nepal produce, spices, and mushrooms.
Future<Map<String, int>> seedProducts({List<String>? selectedCategories, List<String>? selectedSeasons}) async {
  int productSuccess = 0;
  int productError = 0;
  int categorySuccess = 0;
  int categoryError = 0;

  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("Authentication required for seeding.");

  final List<Map<String, dynamic>> nepalProducts = [
    // --- VEGETABLES ---
    {"name": "Amaranth (Latte Saag)", "category": "Vegetables", "season": "Summer", "price": 40, "unit": "bundle", "imageUrl": "https://images.unsplash.com/photo-1594968973184-2228a009965f?q=80&w=1000", "farmName": "Himalayan Organic Farms"},
    {"name": "Bamboo Shoots (Taama)", "category": "Vegetables", "season": "Monsoon", "price": 120, "unit": "500g", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Dhading Agri Hub"},
    {"name": "Beetroot (Chukander)", "category": "Vegetables", "season": "Winter", "price": 80, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1585944672394-4c9979776d23?q=80&w=1000", "farmName": "Valley Green Farms"},
    {"name": "Bitter Gourd (Tite Karela)", "category": "Vegetables", "season": "Summer", "price": 70, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1615485240318-10f4889b9ba1?q=80&w=1000", "farmName": "Terai Greens"},
    {"name": "Bottle Gourd (Lauka)", "category": "Vegetables", "season": "Summer", "price": 50, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1592394933393-0105260f8457?q=80&w=1000", "farmName": "Saptari Organic Farm"},
    {"name": "Broccoli", "category": "Vegetables", "season": "Winter", "price": 120, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?q=80&w=1000", "farmName": "Bungamati Farmers"},
    {"name": "Cabbage (Banda Gobi)", "category": "Vegetables", "season": "All Year", "price": 40, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1591431759433-02324d862f59?q=80&w=1000", "farmName": "Lalitpur Agro Farm"},
    {"name": "Carrot (Gajar)", "category": "Vegetables", "season": "Winter", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=1000", "farmName": "Green Valley Organic"},
    {"name": "Cauliflower (Kauli)", "category": "Vegetables", "season": "Winter", "price": 70, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1568584711075-3d021a7c3ec3?q=80&w=1000", "farmName": "Mountain Fresh Palung"},
    {"name": "Chayote (Iskus)", "category": "Vegetables", "season": "Summer", "price": 30, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1592394933393-0105260f8457?q=80&w=1000", "farmName": "Hilly Harvest"},
    {"name": "Cucumber (Kaakro)", "category": "Vegetables", "season": "Summer", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1449333254728-79e4ad2b9977?q=80&w=1000", "farmName": "Bhaktapur Vegetable Group"},
    {"name": "Eggplant (Bhanta)", "category": "Vegetables", "season": "All Year", "price": 70, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1528137850689-d50d52f3692c?q=80&w=1000", "farmName": "Parsa Agri Farms"},
    {"name": "Fiddlehead Fern (Niuro)", "category": "Vegetables", "season": "Monsoon", "price": 100, "unit": "bundle", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Mountain Wild Harvest"},
    {"name": "Green Beans (Simi)", "category": "Vegetables", "season": "Summer", "price": 80, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1567375639018-09558f68297a?q=80&w=1000", "farmName": "Hilly Harvest"},
    {"name": "Kohlrabi (Gyanth Gobi)", "category": "Vegetables", "season": "Winter", "price": 50, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Valley Veggie Coop"},
    {"name": "Okra (Ramtoriya)", "category": "Vegetables", "season": "Summer", "price": 90, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1567375639018-09558f68297a?q=80&w=1000", "farmName": "Chitwan Agri Hub"},
    {"name": "Onion (Pyaj)", "category": "Vegetables", "season": "All Year", "price": 80, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1508747703725-71977713d540?q=80&w=1000", "farmName": "Terai Harvest"},
    {"name": "Potato (Alu)", "category": "Vegetables", "season": "All Year", "price": 70, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1518977676601-b53f82aba655?q=80&w=1000", "farmName": "Kathmandu Agri Coop"},
    {"name": "Pumpkin (Pharsi)", "category": "Vegetables", "season": "Autumn", "price": 45, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1506815444479-bfdb1e96c566?q=80&w=1000", "farmName": "Terai Harvest"},
    {"name": "Radish (Mula)", "category": "Vegetables", "season": "Winter", "price": 30, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Bhaktapur Roots"},
    {"name": "Spinach (Paalungo)", "category": "Vegetables", "season": "Winter", "price": 50, "unit": "bundle", "imageUrl": "https://images.unsplash.com/photo-1594968973184-2228a009965f?q=80&w=1000", "farmName": "Valley Greens"},
    {"name": "Sweet Potato (Sakhar Khand)", "category": "Vegetables", "season": "Winter", "price": 80, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1596097561442-6be441194565?q=80&w=1000", "farmName": "Terai Sweet Harvest"},
    {"name": "Tamarind (Imli)", "category": "Vegetables", "season": "All Year", "price": 200, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Eastern Spices"},
    {"name": "Taro (Pidaalu)", "category": "Vegetables", "season": "Winter", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Hillside Roots"},
    {"name": "Tomato (Golebheda)", "category": "Vegetables", "season": "All Year", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=1000", "farmName": "Kathmandu Valley Green Farms"},
    {"name": "Turnip (Salgam)", "category": "Vegetables", "season": "Winter", "price": 50, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Lalitpur Agro Farm"},

    // --- FRUITS ---
    {"name": "Apple (Syau)", "category": "Fruits", "season": "Autumn", "price": 260, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=1000", "farmName": "Marpha Himalayan Orchard"},
    {"name": "Apricot (Khurpaani)", "category": "Fruits", "season": "Summer", "price": 350, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Mustang Fruit Estate"},
    {"name": "Banana (Kera)", "category": "Fruits", "season": "All Year", "price": 120, "unit": "dozen", "imageUrl": "https://images.unsplash.com/photo-1603833665858-e61d17a86224?q=80&w=1000", "farmName": "Kavre Banana Farm"},
    {"name": "Bayberry (Kafal)", "category": "Fruits", "season": "Spring", "price": 200, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Forest Harvest"},
    {"name": "Custard Apple (Sariphaa)", "category": "Fruits", "season": "Autumn", "price": 150, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Mid-Hill Orchards"},
    {"name": "Guava (Amba)", "category": "Fruits", "season": "Autumn", "price": 80, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1534073828943-f801091bb18c?q=80&w=1000", "farmName": "Valley Orchards"},
    {"name": "Hog Plum (Lapsi)", "category": "Fruits", "season": "Winter", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Kathmandu Valley Orchards"},
    {"name": "Indian Gooseberry (Amala)", "category": "Fruits", "season": "Winter", "price": 140, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Himalayan Herbs"},
    {"name": "Jackfruit (Rukh Katahar)", "category": "Fruits", "season": "Summer", "price": 100, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Chitwan Fruit Estate"},
    {"name": "Lemon/Lime (Kaagati)", "category": "Fruits", "season": "All Year", "price": 150, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1590502593452-192070f3f232?q=80&w=1000", "farmName": "Nawalpur Citrus"},
    {"name": "Lychee (Lichi)", "category": "Fruits", "season": "Summer", "price": 250, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Rautahat Fruit Belt"},
    {"name": "Mandarin/Orange (Suntala)", "category": "Fruits", "season": "Winter", "price": 160, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1611080626919-7cf5a9caab53?q=80&w=1000", "farmName": "Gulmi Citrus Grove"},
    {"name": "Mango (Aanp)", "category": "Fruits", "season": "Summer", "price": 220, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1553279768-865429fa0078?q=80&w=1000", "farmName": "Saptari Tropical Fruit"},
    {"name": "Mulberry (Kimbu)", "category": "Fruits", "season": "Spring", "price": 180, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Mid-Hill Berries"},
    {"name": "Papaya (Mewaa)", "category": "Fruits", "season": "All Year", "price": 90, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1517282003755-6b3531649987?q=80&w=1000", "farmName": "Chitwan Fruit Estate"},
    {"name": "Peach (Aaru)", "category": "Fruits", "season": "Summer", "price": 180, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1521404113591-2bc8a02a829e?q=80&w=1000", "farmName": "Kathmandu Orchards"},
    {"name": "Pear (Nashpaati)", "category": "Fruits", "season": "Summer", "price": 120, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1514756331096-242f390effee?q=80&w=1000", "farmName": "Valley Fruit Group"},
    {"name": "Persimmon (Haluwaabed)", "category": "Fruits", "season": "Autumn", "price": 200, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Mid-Hill Harvest"},
    {"name": "Pineapple (Bhuin Katahar)", "category": "Fruits", "season": "Summer", "price": 150, "unit": "piece", "imageUrl": "https://images.unsplash.com/photo-1550258114-68bd2950599d?q=80&w=1000", "farmName": "Eastern Fruit Hub"},
    {"name": "Plum (Alubukhara)", "category": "Fruits", "season": "Summer", "price": 160, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Hillside Orchards"},
    {"name": "Pomegranate (Anaar)", "category": "Fruits", "season": "All Year", "price": 380, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1604177042704-338871638f21?q=80&w=1000", "farmName": "Salyan Fruit Farm"},
    {"name": "Pomelo (Bhogate)", "category": "Fruits", "season": "Autumn", "price": 100, "unit": "piece", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Valley Citrus Farm"},
    {"name": "Watermelon (Kharbuja)", "category": "Fruits", "season": "Summer", "price": 60, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1587049352861-81004ccfb8c2?q=80&w=1000", "farmName": "Nawalparasi Agri Group"},

    // --- SPICES (Masala) ---
    {"name": "Asafoetida (Hing)", "category": "Spices", "season": "All Year", "price": 150, "unit": "50g", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=1000", "farmName": "Himalayan Spice Collective"},
    {"name": "Black Cardamom (Alaichi)", "category": "Spices", "season": "All Year", "price": 250, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1510627489930-0c1b0ba80086?q=80&w=1000", "farmName": "Ilam Spice Hub"},
    {"name": "Black Pepper (Marich)", "category": "Spices", "season": "All Year", "price": 180, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1532336414038-cf19250c5757?q=80&w=1000", "farmName": "Surkhet Spice Mill"},
    {"name": "Carom Seeds (Jwano)", "category": "Spices", "season": "All Year", "price": 60, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1599590984817-0314752674e2?q=80&w=1000", "farmName": "Local Herb Collective"},
    {"name": "Cinnamon (Dalchini)", "category": "Spices", "season": "All Year", "price": 120, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=1000", "farmName": "Tropical Spice Farm"},
    {"name": "Clove (Lwang)", "category": "Spices", "season": "All Year", "price": 300, "unit": "50g", "imageUrl": "https://images.unsplash.com/photo-1595123550441-d377e017de6a?q=80&w=1000", "farmName": "Surkhet Spice Mill"},
    {"name": "Coriander Seeds (Dhaniya)", "category": "Spices", "season": "All Year", "price": 80, "unit": "200g", "imageUrl": "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?q=80&w=1000", "farmName": "Valley Spice Coop"},
    {"name": "Cumin Seeds (Jeera)", "category": "Spices", "season": "All Year", "price": 150, "unit": "200g", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=1000", "farmName": "Terai Spice Hub"},
    {"name": "Fenugreek Seeds (Methi)", "category": "Spices", "season": "All Year", "price": 70, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1589135339683-17639c7f9995?q=80&w=1000", "farmName": "Local Garden Coop"},
    {"name": "Garlic (Lashun)", "category": "Spices", "season": "All Year", "price": 400, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?q=80&w=1000", "farmName": "Hillside Spice Coop"},
    {"name": "Ginger (Aduwa)", "category": "Spices", "season": "All Year", "price": 150, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=1000", "farmName": "Palpa Ginger Hub"},
    {"name": "Mustard Seeds (Tori)", "category": "Spices", "season": "All Year", "price": 90, "unit": "500g", "imageUrl": "https://images.unsplash.com/photo-1615485240318-10f4889b9ba1?q=80&w=1000", "farmName": "Terai Harvest"},
    {"name": "Nutmeg (Jaiphal)", "category": "Spices", "season": "All Year", "price": 100, "unit": "piece", "imageUrl": "https://images.unsplash.com/photo-1593390191839-38f45f9429ba?q=80&w=1000", "farmName": "Highland Spices"},
    {"name": "Sichuan Pepper (Timur)", "category": "Spices", "season": "Autumn", "price": 120, "unit": "100g", "imageUrl": "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?q=80&w=1000", "farmName": "Surkhet Spice Hub"},
    {"name": "Turmeric (Besar)", "category": "Spices", "season": "All Year", "price": 180, "unit": "250g", "imageUrl": "https://images.unsplash.com/photo-1615485240318-10f4889b9ba1?q=80&w=1000", "farmName": "Salyan Organic Village"},

    // --- MUSHROOMS (Chau) ---
    {"name": "Button Mushroom", "category": "Mushrooms", "season": "All Year", "price": 300, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1567608285749-c6bb167c9c07?q=80&w=1000", "farmName": "Valley Mushroom Farm"},
    {"name": "Oyster Mushroom", "category": "Mushrooms", "season": "All Year", "price": 250, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1612141853201-20bf3682496d?q=80&w=1000", "farmName": "Kavre Organic Hub"},
    {"name": "Shiitake Mushroom", "category": "Mushrooms", "season": "All Year", "price": 800, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1504675099198-7023dd85f5a3?q=80&w=1000", "farmName": "Hillside Mushroom Coop"},
    {"name": "Wild Forest Mushrooms", "category": "Mushrooms", "season": "Monsoon", "price": 1200, "unit": "kg", "imageUrl": "https://images.unsplash.com/photo-1504675099198-7023dd85f5a3?q=80&w=1000", "farmName": "Forest Community Groups"},
  ];

  final CollectionReference products = FirebaseFirestore.instance.collection('master_catalog');

  for (var product in nepalProducts) {
    bool catMatch = selectedCategories == null || selectedCategories.contains(product['category']);
    bool seasonMatch = selectedSeasons == null || selectedSeasons.contains(product['season']) || product['season'] == 'All Year';

    if (catMatch && seasonMatch) {
      try {
        product['addedAt'] = FieldValue.serverTimestamp();
        product['updatedAt'] = FieldValue.serverTimestamp();
        product['rating'] = 4.8;
        product['image'] = product['imageUrl'];
        product['title'] = product['name'];
        product['description'] = "Fresh produce from Nepal.";
        product['longDescription'] = "High-quality local produce grown with care in the fertile lands of Nepal.";
        
        String docId = product['name'].toString().replaceAll(' ', '_').toLowerCase();
        
        await products.doc(docId).set(product, SetOptions(merge: true));
        productSuccess++;
      } catch (e) {
        productError++;
      }
    }
  }

  // Categories seed
  final List<Map<String, dynamic>> categoriesData = [
    {"name": "Vegetables", "iconCode": Icons.eco_outlined.codePoint},
    {"name": "Fruits", "iconCode": Icons.apple_outlined.codePoint},
    {"name": "Dairy", "iconCode": Icons.local_drink_outlined.codePoint},
    {"name": "Grains", "iconCode": Icons.grain.codePoint},
    {"name": "Tea & Coffee", "iconCode": Icons.local_cafe_outlined.codePoint},
    {"name": "Spices", "iconCode": Icons.flare.codePoint},
    {"name": "Pulses", "iconCode": Icons.lens_blur.codePoint},
    {"name": "Mushrooms", "iconCode": Icons.spa.codePoint},
    {"name": "Specialty", "iconCode": Icons.star_border.codePoint},
  ];

  final CollectionReference categoriesCol = FirebaseFirestore.instance.collection('categories');
  for (var cat in categoriesData) {
    try {
      await categoriesCol.doc(cat['name']).set(cat, SetOptions(merge: true));
      categorySuccess++;
    } catch (e) {
      categoryError++;
    }
  }
  
  return {
    'productSuccess': productSuccess,
    'productError': productError,
    'categorySuccess': categorySuccess,
    'categoryError': categoryError,
  };
}
