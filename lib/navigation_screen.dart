import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/my_cart.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';

class NavigationScreen extends StatefulWidget {
  final String userName;
  const NavigationScreen({super.key, required this.userName});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentIndex = 0;

  // ── SHARED FAVOURITES STATE ──────────────────────────────────────────────
  final Set<String> _favouriteNames = {};
  final List<Map<String, dynamic>> _allProducts = [
    {'name': 'Fresh Tomato (गोलभेंडा)', 'price': 130, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Kavre Organic Farm', 'badge': '100% Organic', 'badgeColor': Colors.green, 'rating': 4.8, 'reviews': 129, 'imagePath': 'tomato.png', 'discount': null},
    {'name': 'Organic Potato (आलु)', 'price': 60, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Himalayan Farms', 'badge': 'Pesticide Free', 'badgeColor': Colors.blue, 'rating': 4.5, 'reviews': 98, 'imagePath': 'potato png.png', 'discount': null},
    {'name': 'Green Cabbage (बन्दा गोभी)', 'price': 80, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Bhaktapur Fresh Farm', 'badge': 'Fresh Picked', 'badgeColor': Colors.orange, 'rating': 4.3, 'reviews': 76, 'imagePath': 'green cabbage.png', 'discount': null},
    {'name': 'Fresh Spinach (पालुङ्गो)', 'price': 45, 'unit': 'bunch', 'category': 'Vegetables', 'farm': 'Green Valley Organics', 'badge': '100% Organic', 'badgeColor': Colors.green, 'rating': 4.6, 'reviews': 54, 'imagePath': 'spinach.png', 'discount': null},
    {'name': 'Fresh Cucumber (काक्रो)', 'price': 40, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Terai Produce Co-op', 'badge': 'Fresh Harvest', 'badgeColor': Colors.teal, 'rating': 4.4, 'reviews': 58, 'imagePath': 'tomato.png', 'discount': 5},
    {'name': 'Eggplant (भण्टा)', 'price': 65, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Dhading Vegetable Growers', 'badge': 'Organic', 'badgeColor': Colors.purple, 'rating': 4.2, 'reviews': 41, 'imagePath': 'eggplant.png', 'discount': null},
    {'name': 'Bitter Gourd (करेला)', 'price': 55, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Hetauda Green Farms', 'badge': 'Pesticide-Free', 'badgeColor': Colors.blue, 'rating': 4.1, 'reviews': 37, 'imagePath': 'bitter gourd.png', 'discount': null},
    {'name': 'Fresh Radish (मुला)', 'price': 48, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Kavre Root Vegetable Co-op', 'badge': 'Organic', 'badgeColor': Colors.green, 'rating': 4.5, 'reviews': 61, 'imagePath': 'Radish.png', 'discount': 10},
    {'name': 'Okra (भिन्डी)', 'price': 70, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Sindhuli Organic Farms', 'badge': 'Fresh', 'badgeColor': Colors.orange, 'rating': 4.3, 'reviews': 44, 'imagePath': 'okra.png', 'discount': null},
    {'name': 'French Beans (सेम)', 'price': 85, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Nuwakot Green Harvest', 'badge': 'Pesticide-Free', 'badgeColor': Colors.blue, 'rating': 4.6, 'reviews': 72, 'imagePath': 'french beans.png', 'discount': 5},
    {'name': 'Carrot (गाजर)', 'price': 95, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Chitwan Farm Market', 'badge': 'Fresh', 'badgeColor': Colors.deepOrange, 'rating': 4.4, 'reviews': 84, 'imagePath': 'carrot.png', 'discount': null},
    {'name': 'Pumpkin (फर्सी)', 'price': 50, 'unit': 'kg', 'category': 'Vegetables', 'farm': 'Lalitpur Organic Farm', 'badge': 'Seasonal', 'badgeColor': Colors.amber, 'rating': 4.2, 'reviews': 39, 'imagePath': 'pumpkin.png', 'discount': null},
    {'name': 'Ripe Mango (आम)', 'price': 200, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Terai Fruit Gardens', 'badge': 'Seasonal', 'badgeColor': Colors.amber, 'rating': 4.7, 'reviews': 143, 'imagePath': 'mango.png', 'discount': null},
    {'name': 'Banana (केरा)', 'price': 80, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Chitwan Banana Farm', 'badge': 'Fresh', 'badgeColor': Colors.orange, 'rating': 4.8, 'reviews': 189, 'imagePath': 'banana.png', 'discount': null},
    {'name': 'Apple (स्याउ)', 'price': 160, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Mustang Orchards', 'badge': 'Himalayan', 'badgeColor': Colors.red, 'rating': 4.9, 'reviews': 210, 'imagePath': 'apple.png', 'discount': 10},
    {'name': 'Papaya (मेवा)', 'price': 70, 'unit': 'kg', 'category': 'Fruits', 'farm': 'Narayangarh Fruit Growers', 'badge': 'Local', 'badgeColor': Colors.amber, 'rating': 4.4, 'reviews': 57, 'imagePath': 'papaya.png', 'discount': null},
    {'name': 'Farm Fresh Milk (दूध)', 'price': 90, 'unit': 'litre', 'category': 'Dairy', 'farm': 'Sunrise Dairy Farm', 'badge': 'A2 Milk', 'badgeColor': Colors.teal, 'rating': 4.9, 'reviews': 210, 'imagePath': 'milk png.png', 'discount': 10},
    {'name': 'Curd (दही)', 'price': 120, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Sunrise Dairy Farm', 'badge': 'Farm Fresh', 'badgeColor': Colors.teal, 'rating': 4.6, 'reviews': 112, 'imagePath': 'curd.png', 'discount': null},
    {'name': 'Fresh Yogurt (दही)', 'price': 135, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Yogurt Co-op', 'badge': 'Probiotic', 'badgeColor': Colors.teal, 'rating': 4.7, 'reviews': 98, 'imagePath': 'fresh yogurt.png', 'discount': 5},
    {'name': 'Fresh Butter (मखन)', 'price': 420, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Dairy', 'badge': 'Desi', 'badgeColor': Colors.teal, 'rating': 4.8, 'reviews': 87, 'imagePath': 'fresh butter.png', 'discount': null},
    {'name': 'Fresh Ghee (घिउ)', 'price': 850, 'unit': 'kg', 'category': 'Dairy', 'farm': 'Himalayan Ghee Factory', 'badge': 'Pure', 'badgeColor': Colors.teal, 'rating': 4.9, 'reviews': 142, 'imagePath': 'fresh ghee.png', 'discount': null},
    {'name': 'Brown Rice (चामल)', 'price': 180, 'unit': 'kg', 'category': 'Grains', 'farm': 'Chitwan Agro Farm', 'badge': 'Whole Grain', 'badgeColor': Colors.brown, 'rating': 4.4, 'reviews': 67, 'imagePath': 'brown rice.png', 'discount': 5},
    {'name': 'Millet (कोदो)', 'price': 190, 'unit': 'kg', 'category': 'Grains', 'farm': 'Himalayan Millet Co-op', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.5, 'reviews': 52, 'imagePath': 'millet.png', 'discount': null},
    {'name': 'Wheat (गेहुँ)', 'price': 110, 'unit': 'kg', 'category': 'Grains', 'farm': 'Narayangarh Grain Store', 'badge': 'Local', 'badgeColor': Colors.brown, 'rating': 4.3, 'reviews': 48, 'imagePath': 'wheat.png', 'discount': null},
    {'name': 'Maize (मकै)', 'price': 45, 'unit': 'kg', 'category': 'Grains', 'farm': 'Terai Maize Growers', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.2, 'reviews': 40, 'imagePath': 'maize.png', 'discount': null},
    {'name': 'Soybean (सोयाबिन)', 'price': 160, 'unit': 'kg', 'category': 'Grains', 'farm': 'Kavre Soy Growers', 'badge': 'Protein-Rich', 'badgeColor': Colors.brown, 'rating': 4.4, 'reviews': 55, 'imagePath': 'soyabean.png', 'discount': null},
    {'name': 'Himalayan Honey (शहद)', 'price': 850, 'unit': '500g', 'category': 'Organic', 'farm': 'Mountain Bee Farm', 'badge': 'Pure & Raw', 'badgeColor': Colors.brown, 'rating': 4.9, 'reviews': 312, 'imagePath': 'himalayan honey.png', 'discount': null},
    {'name': 'Fresh Ginger (अदुवा)', 'price': 120, 'unit': 'kg', 'category': 'Herbs', 'farm': 'Gorkha Spice Farm', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.6, 'reviews': 78, 'imagePath': 'ginger.png', 'discount': null},
    {'name': 'Fresh Turmeric (बेसार)', 'price': 210, 'unit': 'kg', 'category': 'Herbs', 'farm': 'Gorkha Spice Farm', 'badge': 'Organic', 'badgeColor': Colors.brown, 'rating': 4.8, 'reviews': 92, 'imagePath': 'fresh turmeric.png', 'discount': 5},
  ];

  void _toggleFavourite(Map<String, dynamic> product) {
    setState(() {
      final name = product['name'].toString();
      if (_favouriteNames.contains(name)) {
        _favouriteNames.remove(name);
      } else {
        _favouriteNames.add(name);
      }
    });
  }

  List<Map<String, dynamic>> get _favouriteProducts =>
      _allProducts.where((p) => _favouriteNames.contains(p['name'].toString())).toList();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      CategoriesScreen(
        allProducts: _allProducts,
        favouriteNames: _favouriteNames,
        onFavouriteToggle: _toggleFavourite,
      ),
      const CartScreen(),
      const OrdersScreen(),
      ProfileScreen(
        userName: widget.userName,
        favouriteProducts: _favouriteProducts,
        allProducts: _allProducts,
        favouriteNames: _favouriteNames,
        onFavouriteToggle: _toggleFavourite,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(icon: Icons.home_rounded, label: "Home", index: 0),
              navItem(icon: Icons.grid_view_rounded, label: "Categories", index: 1),
              navItem(icon: Icons.shopping_cart_rounded, label: "Cart", index: 2),
              navItem(icon: Icons.receipt_long_rounded, label: "Orders", index: 3),
              navItem(icon: Icons.person_rounded, label: "Profile", index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1,
              duration: const Duration(milliseconds: 250),
              child: Icon(icon, size: 26, color: isSelected ? Colors.green : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.green : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}