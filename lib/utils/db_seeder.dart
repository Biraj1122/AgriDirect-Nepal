import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Seeds the database with Nepal products and categories.
/// Returns a map with success and error counts.
Future<Map<String, int>> seedProducts({List<String>? selectedCategories, List<String>? selectedSeasons}) async {
  int productSuccess = 0;
  int productError = 0;
  int categorySuccess = 0;
  int categoryError = 0;

  debugPrint("Starting database seeding process...");

  // Check for authentication
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint("Seeding Failed: No authenticated user found.");
    throw Exception("Authentication required. Please sign in again.");
  }
  debugPrint("Authenticated as: ${user.email} (UID: ${user.uid})");

  final List<Map<String, dynamic>> nepalProducts = [
    // --- VEGETABLES ---
    {
      "title": "Rayo Ko Saag",
      "name": "Rayo Ko Saag",
      "category": "Vegetables",
      "season": "Winter",
      "price": 45,
      "unit": "bundle",
      "description": "Organic broad leaf mustard from Bhaktapur.",
      "longDescription": "Freshly harvested Rayo ko Saag from the fertile fields of Bhaktapur. Known for its distinct sharp flavor and high Vitamin A content.",
      "imageUrl": "https://annapurnaexpress.prixacdn.net/media/albums/IMG_2523_UQZnF2Fh0l.jpeg",
      "farmName": "Bhaktapur Organic Farm",
      "badge": "Fresh",
      "badgeColor": 0xFF2E7D32,
    },
    {
      "title": "Mude ko Aloo",
      "name": "Mude ko Aloo",
      "category": "Vegetables",
      "season": "Autumn",
      "price": 75,
      "unit": "kg",
      "description": "Famous red potatoes from Mude, Sindhupalchowk.",
      "longDescription": "These red potatoes are grown in the high altitudes of Mude. They are famous for their texture and taste.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRLPtnQdjTrSieQkYgtuRNsgCxHoIJEs02VklgMAAdwWA&s=10",
      "farmName": "Mude Highland Cooperatives",
      "badge": "Top Rated",
      "badgeColor": 0xFFF57C00,
    },
    {
      "title": "Local Kauli",
      "name": "Local Kauli",
      "category": "Vegetables",
      "season": "Winter",
      "price": 65,
      "unit": "kg",
      "description": "Crispy white cauliflower from Palung valley.",
      "longDescription": "Palung is famous for its off-season cauliflower. These are grown at high altitudes resulting in a sweeter, crispier texture.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwDEaxl5aeZGXdTksnMXYatNvIvKvjr83GSlky0Mc6cM-QkkboLVAy2uI&s=10",
      "farmName": "Mountain Fresh Palung",
      "badge": "High Altitude",
      "badgeColor": 0xFF1976D2,
    },
    {
      "title": "Akabare Khursani",
      "name": "Akabare Khursani",
      "category": "Vegetables",
      "season": "Summer",
      "price": 140,
      "unit": "250g",
      "description": "Extra spicy King Chili from Eastern Nepal.",
      "longDescription": "Known as the King of Chilies, Akabare is famous for its intense heat and wonderful aroma.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS2uyIT9ZzYJwhkM5AzwsKgO-kOzgLnvS1AWD1LAuTHsg&s",
      "farmName": "Eastern Hill Spices",
      "badge": "Hot",
      "badgeColor": 0xFFD32F2F,
    },
    {
      "title": "Gundruk",
      "name": "Gundruk",
      "category": "Vegetables",
      "season": "All Year",
      "price": 120,
      "unit": "200g",
      "description": "Traditional fermented leafy greens.",
      "longDescription": "A national dish of Nepal. Fermented and dried mustard leaves. Perfect for soup.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBBq1FraDTv4m5copij1pXBb3jQK2gjiRJdr4jL-gkKp7khYKnuImqH0SgHn3LH-aW9oW5o4w3huyMM2Ng0my6puBXxPrBfeXWkIXgskxT&s=10",
      "farmName": "Local Village Cooperatives",
      "badge": "Traditional",
      "badgeColor": 0xFF795548,
    },
    {
      "title": "Tama (Bamboo Shoot)",
      "name": "Tama (Bamboo Shoot)",
      "category": "Vegetables",
      "season": "Monsoon",
      "price": 90,
      "unit": "500g",
      "description": "Fermented bamboo shoots for sour curry.",
      "longDescription": "Traditionally fermented bamboo shoots used in the classic 'Aloo Tama' curry.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJqGsB6UUarI9artn_zO4LOzHcP1SH1e-RaMCAJSu1wfjSyS2kHSbPPaEQVgR0AhsT5q9-RWDZO17S0dD2y_s73HhWnMYhowTYvpppQjY&s=10",
      "farmName": "Dhading Agri Hub",
      "badge": "Local",
      "badgeColor": 0xFF689F38,
    },
    {
      "title": "Pharsi (Pumpkin)",
      "name": "Pharsi (Pumpkin)",
      "category": "Vegetables",
      "season": "Autumn",
      "price": 40,
      "unit": "kg",
      "description": "Sweet local pumpkin from the plains.",
      "longDescription": "Rich in Vitamin A, these pumpkins are sweet and perfect for curries or desserts.",
      "imageUrl": "https://www.thegundruk.com/wp-content/uploads/2016/04/Pumkin-and-seed-.jpg",
      "farmName": "Chitwan Agri Farms",
      "badge": "Seasonal",
      "badgeColor": 0xFFFF9800,
    },
    {
      "title": "Mula (Radish)",
      "name": "Mula (Radish)",
      "category": "Vegetables",
      "season": "Winter",
      "price": 30,
      "unit": "kg",
      "description": "Crispy white radish for pickles and salad.",
      "longDescription": "Fresh winter radish, perfect for making traditional sun-dried 'Sinki'.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPevyvfzGM2QofOu9MkY57DnvqcqTHRNidImTlKaGqwH-YS1LyoF2PFTRa&s=10",
      "farmName": "Hetauda Farmhouse",
      "badge": "Winter Special",
      "badgeColor": 0xFF00BCD4,
    },
    {
      "title": "Kharbuja (Watermelon)",
      "name": "Kharbuja (Watermelon)",
      "category": "Fruits",
      "season": "Summer",
      "price": 60,
      "unit": "kg",
      "description": "Sweet and juicy local watermelon from Terai.",
      "longDescription": "Perfect summer refresher. These watermelons are grown in the sandy riverbeds of the Terai region.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSMPc6BMgWZqbUuUQv2u4nqQQjOuyv4dMe6pNgWYb7Eaa0XXdOPL00BxIok&s=10",
      "farmName": "Nawalparasi Agri Group",
      "badge": "Summer Special",
      "badgeColor": 0xFFE91E63,
    },

    // --- FRUITS ---
    {
      "title": "Mustang Apple",
      "name": "Mustang Apple",
      "category": "Fruits",
      "season": "Autumn",
      "price": 240,
      "unit": "kg",
      "description": "Crispy organic apples from the Himalayas.",
      "longDescription": "Grown in Marpha, Mustang. Famous for unique sweetness and crunch.",
      "imageUrl": "https://newbusinessage.prixacdn.net/img/news/20220908022220_apple.jpg",
      "farmName": "Marpha Himalayan Orchard",
      "badge": "Himalayan",
      "badgeColor": 0xFF7B1FA2,
    },
    {
      "title": "Nepali Suntala",
      "name": "Nepali Suntala",
      "category": "Fruits",
      "season": "Winter",
      "price": 130,
      "unit": "kg",
      "description": "Juicy oranges from the hills of Gulmi.",
      "longDescription": "Gulmi is the heart of orange production. Thin-skinned and packed with juice.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNDmD40SiN10jO20eCQMa66J8j_4cg58dQba-Q69rnEw&s=10",
      "farmName": "Gulmi Citrus Grove",
      "badge": "Sweet",
      "badgeColor": 0xFFFFA000,
    },
    {
      "title": "Terai Malda Mango",
      "name": "Terai Malda Mango",
      "category": "Fruits",
      "season": "Summer",
      "price": 180,
      "unit": "kg",
      "description": "The king of mangoes from Saptari.",
      "longDescription": "The most sought-after mango variety in Nepal. No carbides used.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy-ydt07SVkXwljy3e-2bDOhp-GVErz87lW7FmE4eUdLpuNfnuWprBsi0&s=10",
      "farmName": "Saptari Tropical Fruit",
      "badge": "Premium",
      "badgeColor": 0xFFFFD600,
    },
    {
      "title": "Litchi",
      "name": "Litchi",
      "category": "Fruits",
      "season": "Summer",
      "price": 200,
      "unit": "kg",
      "description": "Sweet Shahi Litchi from Rautahat.",
      "longDescription": "Seasonal summer delight, juicy and sweet from the Terai orchards.",
      "imageUrl": "https://dharaseeds.com/cdn/shop/files/._lychee-seeds-litchi-chinensis.jpg?v=1764912039",
      "farmName": "Rautahat Fruit Belt",
      "badge": "Juicy",
      "badgeColor": 0xFFE91E63,
    },

    // --- GRAINS ---
    {
      "title": "Jumli Marshi Rice",
      "name": "Jumli Marshi Rice",
      "category": "Grains",
      "season": "Autumn",
      "price": 280,
      "unit": "kg",
      "description": "Indigenous red rice from Jumla.",
      "longDescription": "Grown at high altitudes. Cold-resistant and highly nutritious.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqbAAlLF0FF-sM8PvznFrbRHz59z0inOGK43eEuxAT0Q&s=10",
      "farmName": "Karnali Highland Grains",
      "badge": "Ancient Grain",
      "badgeColor": 0xFF8D6E63,
    },
    {
      "title": "Local Kodo (Millet)",
      "name": "Local Kodo (Millet)",
      "category": "Grains",
      "season": "Winter",
      "price": 95,
      "unit": "kg",
      "description": "High-fiber finger millet from Kavre.",
      "longDescription": "Organic finger millet traditionally used to make Dhido.",
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5dVjfkPa413A_NJi6981RsKNhlHzWXikkyhi6umTdxJLrC5dUg-brLTG4&s=10",
      "farmName": "Kavre Hillside Farming",
      "badge": "Superfood",
      "badgeColor": 0xFF6D4C41,
    },
    {
      "title": "Phapar (Buckwheat)",
      "name": "Phapar (Buckwheat)",
      "category": "Grains",
      "season": "Autumn",
      "price": 150,
      "unit": "kg",
      "description": "Nutritious buckwheat from Mustang.",
      "longDescription": "Naturally gluten-free grain used for traditional rotis in the mountains.",
      "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=500&auto=format&fit=crop",
      "farmName": "Mustang Crop Center",
      "badge": "Gluten Free",
      "badgeColor": 0xFF4CAF50,
    },

    // --- DAIRY ---
    {
      "title": "Local Ghiu (Ghee)",
      "name": "Local Ghiu (Ghee)",
      "category": "Dairy",
      "season": "All Year",
      "price": 1300,
      "unit": "kg",
      "description": "Pure buffalo milk clarified butter.",
      "longDescription": "Traditional Ghiu with rich aroma. Essential healthy fat.",
      "imageUrl": "https://images.unsplash.com/photo-1631209121575-2042d87a8831?q=80&w=500&auto=format&fit=crop",
      "farmName": "Lalitpur Dairy Farmers",
      "badge": "Pure",
      "badgeColor": 0xFFFFB300,
    },
    {
      "title": "Chhurpi",
      "name": "Chhurpi",
      "category": "Dairy",
      "season": "All Year",
      "price": 350,
      "unit": "200g",
      "description": "Himalayan hard cheese (Yak milk).",
      "longDescription": "The world's hardest cheese. High in protein.",
      "imageUrl": "https://images.unsplash.com/photo-1485921325833-c519f76c4927?q=80&w=500&auto=format&fit=crop",
      "farmName": "Solu Highland Dairy",
      "badge": "Himalayan",
      "badgeColor": 0xFF303F9F,
    },

    // --- SPICES ---
    {
      "title": "Organic Beshar",
      "name": "Organic Beshar",
      "category": "Spices",
      "season": "All Year",
      "price": 180,
      "unit": "250g",
      "description": "Pure Turmeric powder from Salyan.",
      "longDescription": "High curcumin content and deep orange color.",
      "imageUrl": "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?q=80&w=500&auto=format&fit=crop",
      "farmName": "Salyan Organic Village",
      "badge": "Pure",
      "badgeColor": 0xFFFF6F00,
    },
    {
      "title": "Timmur",
      "name": "Timmur",
      "category": "Spices",
      "season": "Autumn",
      "price": 150,
      "unit": "100g",
      "description": "Szechuan Pepper from the hills.",
      "longDescription": "Unique numbing sensation and citrus aroma.",
      "imageUrl": "https://images.unsplash.com/photo-1593504049359-74330189a345?q=80&w=500&auto=format&fit=crop",
      "farmName": "Surkhet Spice Hub",
      "badge": "Unique Flavor",
      "badgeColor": 0xFF607D8B,
    },
    {
      "title": "Jimbu",
      "name": "Jimbu",
      "category": "Spices",
      "season": "Summer",
      "price": 120,
      "unit": "50g",
      "description": "Himalayan dried aromatic herb.",
      "longDescription": "Essential for tempering Nepali dal.",
      "imageUrl": "https://images.unsplash.com/photo-1508747703725-71977713728a?q=80&w=500&auto=format&fit=crop",
      "farmName": "Mountain Herb Collective",
      "badge": "Aromatic",
      "badgeColor": 0xFF4CAF50,
    },

    // --- TEA & COFFEE ---
    {
      "title": "Ilam Orthodox Tea",
      "name": "Ilam Orthodox Tea",
      "category": "Tea & Coffee",
      "season": "Spring",
      "price": 450,
      "unit": "100g",
      "description": "Premium whole leaf black tea from Ilam.",
      "longDescription": "Hand-rolled orthodox tea from Ilam gardens.",
      "imageUrl": "https://images.unsplash.com/photo-1594631252845-29fc458631b6?q=80&w=500&auto=format&fit=crop",
      "farmName": "Ilam Green Hills",
      "badge": "Export Quality",
      "badgeColor": 0xFF00796B,
    },
    {
      "title": "Gulmi Coffee",
      "name": "Gulmi Coffee",
      "category": "Tea & Coffee",
      "season": "Winter",
      "price": 850,
      "unit": "250g",
      "description": "Arabica coffee beans from Gulmi.",
      "longDescription": "Single-origin Arabica coffee grown in the shade.",
      "imageUrl": "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=500&auto=format&fit=crop",
      "farmName": "Gulmi Coffee Estate",
      "badge": "Arabica",
      "badgeColor": 0xFF4E342E,
    },

    // --- SPECIALTY ---
    {
      "title": "Mustang Maha (Honey)",
      "name": "Mustang Maha (Honey)",
      "category": "Specialty",
      "season": "Spring",
      "price": 1100,
      "unit": "500g",
      "description": "Wild Himalayan honey from Mustang.",
      "longDescription": "Raw, unprocessed honey with medicinal properties.",
      "imageUrl": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?q=80&w=500&auto=format&fit=crop",
      "farmName": "Mustang Bee Keepers",
      "badge": "Medicinal",
      "badgeColor": 0xFFFBC02D,
    },
    {
      "title": "Shilajit",
      "name": "Shilajit",
      "category": "Specialty",
      "season": "All Year",
      "price": 1500,
      "unit": "50g",
      "description": "Pure Himalayan mineral pitch.",
      "longDescription": "Traditional wellness supplement collected from high altitude rocks.",
      "imageUrl": "https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?q=80&w=500&auto=format&fit=crop",
      "farmName": "High Altitude Collective",
      "badge": "Ancient Secret",
      "badgeColor": 0xFF212121,
    },
    {
      "title": "Lapsi (Hog Plum)",
      "name": "Lapsi (Hog Plum)",
      "category": "Fruits",
      "season": "Winter",
      "price": 60,
      "unit": "kg",
      "description": "Sour hog plums perfect for pickles.",
      "longDescription": "Unique to Nepal, Lapsi is used for making candies (Titaura) and pickles. High in Vitamin C.",
      "imageUrl": "https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?q=80&w=500&auto=format&fit=crop",
      "farmName": "Kathmandu Valley Orchards",
      "badge": "Local Favorite",
      "badgeColor": 0xFF8BC34A,
    },
    {
      "title": "Sisnu Powder",
      "name": "Sisnu Powder",
      "category": "Specialty",
      "season": "All Year",
      "price": 250,
      "unit": "200g",
      "description": "Nutritious stinging nettle powder.",
      "longDescription": "Himalayan superfood. Rich in iron and calcium. Used for making traditional soup.",
      "imageUrl": "https://images.unsplash.com/photo-1515471204579-2baaccaba2e3?q=80&w=500&auto=format&fit=crop",
      "farmName": "Hillside Organic Herbs",
      "badge": "Superfood",
      "badgeColor": 0xFF43A047,
    },
    {
      "title": "Local Bodi",
      "name": "Local Bodi",
      "category": "Vegetables",
      "season": "Summer",
      "price": 85,
      "unit": "kg",
      "description": "Long green beans from the Terai.",
      "longDescription": "Fresh and tender long beans, a summer staple in Nepali households.",
      "imageUrl": "https://images.unsplash.com/photo-1506484334402-40f299b07b17?q=80&w=500&auto=format&fit=crop",
      "farmName": "Jhapa Agri Farms",
      "badge": "Fresh",
      "badgeColor": 0xFF4CAF50,
    },
    {
      "title": "Amala (Gooseberry)",
      "name": "Amala (Gooseberry)",
      "category": "Fruits",
      "season": "Winter",
      "price": 110,
      "unit": "kg",
      "description": "Wild Himalayan gooseberries.",
      "longDescription": "Powerhouse of Vitamin C. Great for immunity and digestion.",
      "imageUrl": "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?q=80&w=500&auto=format&fit=crop",
      "farmName": "Community Forest Groups",
      "badge": "Immunity",
      "badgeColor": 0xFF009688,
    },
    {
      "title": "Kashmiri Lehsun",
      "name": "Kashmiri Lehsun",
      "category": "Vegetables",
      "season": "All Year",
      "price": 300,
      "unit": "100g",
      "description": "Single-clove garlic with high medicinal value.",
      "longDescription": "Also known as Snow Mountain Garlic. Found in high altitudes, extremely pungent.",
      "imageUrl": "https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?q=80&w=500&auto=format&fit=crop",
      "farmName": "Himalayan High Yields",
      "badge": "Rare",
      "badgeColor": 0xFF795548,
    },
    {
      "title": "Bakula (Broad Beans)",
      "name": "Bakula (Broad Beans)",
      "category": "Vegetables",
      "season": "Spring",
      "price": 90,
      "unit": "kg",
      "description": "Nutritious seasonal broad beans.",
      "longDescription": "A favorite spring vegetable in the Kathmandu valley, often cooked with potatoes.",
      "imageUrl": "https://images.unsplash.com/photo-1515471291241-02685045610d?q=80&w=500&auto=format&fit=crop",
      "farmName": "Bungamati Farmers",
      "badge": "Seasonal",
      "badgeColor": 0xFF8BC34A,
    },
    {
      "title": "Toriko Tel",
      "name": "Toriko Tel",
      "category": "Specialty",
      "season": "All Year",
      "price": 320,
      "unit": "liter",
      "description": "Pure cold-pressed mustard oil.",
      "longDescription": "Traditionally extracted oil from local mustard seeds. Essential for Nepali cooking.",
      "imageUrl": "https://images.unsplash.com/photo-1474979266404-7eaacbadcbaf?q=80&w=500&auto=format&fit=crop",
      "farmName": "Traditional Kol Mills",
      "badge": "Pure",
      "badgeColor": 0xFFFFC107,
    },
    // --- PULSES & LENTILS ---
    {
      "title": "Local Maas ko Daal",
      "name": "Local Maas ko Daal",
      "category": "Pulses",
      "season": "Autumn",
      "price": 180,
      "unit": "kg",
      "description": "Black gram from the mid-hills.",
      "longDescription": "High-protein black gram, essential for the traditional Nepali 'Maas ko Daal'.",
      "imageUrl": "https://images.unsplash.com/photo-1585996853884-bd9c8a8e1e1a?q=80&w=500&auto=format&fit=crop",
      "farmName": "Sindhupalchowk Agro",
      "badge": "High Protein",
      "badgeColor": 0xFF4E342E,
    },
    {
      "title": "Mustang Simi",
      "name": "Mustang Simi",
      "category": "Pulses",
      "season": "Autumn",
      "price": 350,
      "unit": "kg",
      "description": "Famous mountain beans from Mustang.",
      "longDescription": "Grown in the high-altitude trans-Himalayan region. Famous for their unique taste and quick cooking time.",
      "imageUrl": "https://images.unsplash.com/photo-1551462147-37885acc3c41?q=80&w=500&auto=format&fit=crop",
      "farmName": "Thak Khola Cooperatives",
      "badge": "Himalayan",
      "badgeColor": 0xFF1976D2,
    },
    // --- MUSHROOMS ---
    {
      "title": "Local Gobre Chyau",
      "name": "Local Gobre Chyau",
      "category": "Mushrooms",
      "season": "Winter",
      "price": 250,
      "unit": "kg",
      "description": "Fresh Button Mushrooms from Kathmandu valley.",
      "longDescription": "Organic button mushrooms grown in controlled environments in the outskirts of Kathmandu.",
      "imageUrl": "https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?q=80&w=500&auto=format&fit=crop",
      "farmName": "Valley Mushroom Farm",
      "badge": "Freshly Picked",
      "badgeColor": 0xFF689F38,
    }
  ];

  final CollectionReference products = FirebaseFirestore.instance.collection('products');
  debugPrint("Beginning products seeding. Target products: ${nepalProducts.length}");

  for (var product in nepalProducts) {
    bool catMatch = selectedCategories == null || selectedCategories.contains(product['category']);
    bool seasonMatch = selectedSeasons == null || selectedSeasons.contains(product['season']) || product['season'] == 'All Year';

    if (catMatch && seasonMatch) {
      try {
        product['addedAt'] = FieldValue.serverTimestamp();
        product['updatedAt'] = FieldValue.serverTimestamp();
        product['stock'] = 100;
        product['rating'] = 4.8;
        product['image'] = product['imageUrl'];
        product['farmerUid'] = 'admin'; // Mark as seeded by admin
        
        String docId = product['name'].toString().replaceAll(' ', '_').toLowerCase();
        
        // Use a timeout for web stability
        await products.doc(docId).set(product, SetOptions(merge: true)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception("Write timeout for ${product['name']}"),
        );
        
        productSuccess++;
        debugPrint("✓ Seeded Product: ${product['name']}");
      } catch (e) {
        productError++;
        debugPrint("✗ Error seeding product ${product['name']}: $e");
      }
    }
  }

  // Categories seed logic
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
  debugPrint("Beginning categories seeding. Target categories: ${categoriesData.length}");

  for (var cat in categoriesData) {
    try {
      if (selectedCategories == null || selectedCategories.contains(cat['name'])) {
        await categoriesCol.doc(cat['name']).set(cat, SetOptions(merge: true)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception("Write timeout for category ${cat['name']}"),
        );
        categorySuccess++;
        debugPrint("✓ Seeded Category: ${cat['name']}");
      }
    } catch (e) {
      categoryError++;
      debugPrint("✗ Error seeding category ${cat['name']}: $e");
    }
  }

  debugPrint("Seeding Finished. Products: $productSuccess success / $productError error. Categories: $categorySuccess success / $categoryError error.");
  
  return {
    'productSuccess': productSuccess,
    'productError': productError,
    'categorySuccess': categorySuccess,
    'categoryError': categoryError,
  };
}
