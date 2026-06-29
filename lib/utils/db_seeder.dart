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
    {
      "title": "Local Adhuwa (Ginger)",
      "name": "Local Adhuwa (Ginger)",
      "category": "Vegetables",
      "season": "All Year",
      "price": 120,
      "unit": "kg",
      "description": "Organic fresh ginger from Palpa.",
      "longDescription": "High-quality fresh ginger roots from Palpa, known for their strong aroma and medicinal properties. Essential for Nepali tea and curries.",
      "s3Url": "s3://agridirectproducts/Vegetables/ginger.png",
      "imageUrl": "https://agridirectproducts.s3.ap-south-1.amazonaws.com/Vegetables/ginger.png",
      "image": "ginger.png",
      "farmName": "Palpa Ginger Cooperatives",
      "badge": "Organic",
      "badgeColor": 0xFF2E7D32,
    },
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
      "s3Url": "s3://agridirectproducts/Vegetables/Rayo_Ko_Saag.jpg", // Pointing to your S3 folder
      "imageUrl": "https://agridirectproducts.s3.ap-south-1.amazonaws.com/Vegetables/Rayo_Ko_Saag.jpg",
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
      "s3Url": "s3://agridirectproducts/Vegetables/Mude_ko_Aloo.jpg",
      "imageUrl": "https://agridirectproducts.s3.ap-south-1.amazonaws.com/Vegetables/Mude_ko_Aloo.jpg",
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
      "s3Url": "s3://agridirectproducts/Vegetables/Local_Kauli.jpg",
      "imageUrl": "https://agridirectproducts.s3.ap-south-1.amazonaws.com/Vegetables/Local_Kauli.jpg",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRz-8jR26xUoX7o_7i2R0U9vI_rI9HhE7D8Xw&s",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRLQydEO6UjvJxzOhy80rkcJ3Tmvtvk3TTrE7FsLziL0d6u5TwWXbDVEdhbnO9vQKwHYYDTBZ1WKlK-o0hrstWN5fF1QfixqcNxBcHUg0CK&s=10",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSf_x-vE7N1Z-rVwXU8_3u6E9N4J4pS1_X_Rw&s",
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
      "imageUrl": "https://sewapoint.com/image-categories/image-1732717993576-Screenshot%20from%202024-11-27%2020-16-16.png",
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
      "imageUrl": "https://media.cnn.com/api/v1/images/stellar/prod/170201133809-turmeric-stock.jpg?q=w_2187,h_1458,x_0,y_0,c_fill/w_860",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS0hJ-ZY73qroKz3CY7K-4Lq-6askmQ5weoGkvzhUEVKqIZpV8qJFMfeTc&s=10",
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
      "imageUrl": "https://static-01.daraz.com.np/p/e0c276137a5fa9fa77bd7298fb7fe455.png",
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
      "imageUrl": "https://5.imimg.com/data5/MZ/XD/MJ/SELLER-40053611/organic-orthodox-tea-500x500-500x500.jpg",
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
      "imageUrl": "https://newbusinessage.prixacdn.net/img/news/20161212014337_coffee.jpg",
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
      "imageUrl": "https://cdn.mos.cms.futurecdn.net/zcz8f72orNC9GKgm3tbqMY.jpg",
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
      "imageUrl": "https://np-live-21.slatic.net/kf/Sb594a31d35614641aed803c14b7a9b2f9.jpg",
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
      "imageUrl": "https://growbilliontrees.com/cdn/shop/articles/hog-plum-green-paradise1_1200x1200_a70ee307-075b-4139-a401-ebfe8dfd8f82.png?v=1741104672",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRx6sUKI1CS3iHN-0rFGlQRm7q6RuO9iabraK2jV6gBmQ&s=10",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSn9dbRdmdvcO6G_TjDfzR2zOtRbS-UGwp_DH7VhXqftw&s=10",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQHRTa-nlrrUjIt1hQ3ym1nVWkOozDbQYBZ4SYyiJJatQ&s=10",
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
      "imageUrl": "https://5.imimg.com/data5/SELLER/Default/2024/10/459928939/WX/VV/UH/13450502/kashmiri-wild-garlic.jpg",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREoV9A9K8xZ7U7V4jS1L8-4_K-Lp8Z2N6S7Q&s",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpVQ-vgtvmR2rTy0gCajGafpPFEksYnIe7r2T-1vVyRz66Zr5ZcDVoOfo&s=10",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSQ3e0L8-yh3zd89_RtwI6jQm7aF7GmMQn6KuoWQCIjqQ&s=10",
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
      "imageUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS255-VllVHGoFs5Nk2UJRqwdVX8MXLXAaX8kGI4vidRg&s=10",
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
      "imageUrl": "data:image/jpeg;base64,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",
      "farmName": "Valley Mushroom Farm",
      "badge": "Freshly Picked",
      "badgeColor": 0xFF689F38,
    }
  ];

  final CollectionReference products = FirebaseFirestore.instance.collection('master_catalog');
  debugPrint("Beginning catalog seeding. Target products: ${nepalProducts.length}");

  // Also seed into 'products' collection for immediate display if needed, 
  // or ensure the app reads from master_catalog. 
  // Based on the app structure, 'products' is usually where items are listed.
  final CollectionReference liveProducts = FirebaseFirestore.instance.collection('products');

  for (var product in nepalProducts) {
    bool catMatch = selectedCategories == null || selectedCategories.contains(product['category']);
    bool seasonMatch = selectedSeasons == null || selectedSeasons.contains(product['season']) || product['season'] == 'All Year';

    if (catMatch && seasonMatch) {
      try {
        product['addedAt'] = FieldValue.serverTimestamp();
        product['updatedAt'] = FieldValue.serverTimestamp();
        product['rating'] = 4.8;
        product['image'] = product['imageUrl'];
        
        String docId = product['name'].toString().replaceAll(' ', '_').toLowerCase();
        
        // Use a timeout for web stability
        await products.doc(docId).set(product, SetOptions(merge: true)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception("Write timeout for ${product['name']}"),
        );

        // Also add to the main products collection so they show up in the app
        // We set a default farmerUid if one isn't present, or leave it for the store to handle
        Map<String, dynamic> liveProduct = Map.from(product);
        liveProduct['isSample'] = true;
        await liveProducts.doc(docId).set(liveProduct, SetOptions(merge: true));
        
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
