import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/screens/home/home_screen.dart';
import 'package:farmtech_agridirect/screens/my_cart.dart';
import 'package:farmtech_agridirect/screens/shop/categories_screen.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';
import 'package:farmtech_agridirect/screens/profile/profile_screen.dart';
import 'package:farmtech_agridirect/screens/profile/my_favourites.dart';
import '../profile/edit_profile_screen.dart';
import '../misc/farmer_screen.dart';
import '../delivery_person_screen.dart';
import '../admin_page.dart';
import '../auth/login_screen.dart';

class NavigationScreen extends StatefulWidget {
  final String userName;
  final int initialTabIndex;

  const NavigationScreen({
    super.key,
    required this.userName,
    this.initialTabIndex = 0,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const Color primaryTeal = Color(0xFF1D9E75);
  static const Color secondaryBlue = Color(0xFF2E5BFF);
  
  late int currentIndex;
  String selectedCategory = "All";
  bool _isCheckingRole = true;

  List<Map<String, dynamic>> _favouriteProducts = [];
  List<Map<String, dynamic>> _categories = [];
  StreamSubscription? _favSubscription;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialTabIndex;
    _checkRole();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _categories = snapshot.docs.map((doc) {
            final data = doc.data();
            final iconCode = data['iconCode'] as int?;
            return {
              'name': data['name'] ?? 'Category',
              'icon': iconCode != null
                  ? IconData(iconCode, fontFamily: 'MaterialIcons')
                  : Icons.category,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error pre-fetching categories: $e");
    }
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logout();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));
          
      final role = doc.data()?['role'];

      if (mounted) {
        if (role != 'Customer' && role != null && role != 'Admin') {
          // Mandatory Profile Photo Check for Partners
          final profileImg = doc.data()?['profileImageUrl'];
          if (profileImg == null || profileImg.toString().isEmpty) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => EditProfileScreen(
                currentName: doc.data()?['fullName'] ?? user.displayName ?? "Partner",
                currentPhone: doc.data()?['phone'] ?? "Not set",
                mandatoryPhoto: true,
              ))
            );
            return;
          }

          Widget target;
          if (role == 'Farmer') {
            target = const FarmerScreen();
          } else if (role == 'Delivery Person') {
            target = const DeliveryPersonScreen();
          } else {
            setState(() => _isCheckingRole = false);
            return;
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
          return;
        }
        _listenToFavorites();
        setState(() => _isCheckingRole = false);
      }
    } catch (e) {
      debugPrint("Role check timed out or failed: $e. Defaulting to Customer.");
      if (mounted) {
        _listenToFavorites();
        setState(() => _isCheckingRole = false);
      }
    }
  }

  void _logout() {
    if (mounted) {
      FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _listenToFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favSubscription?.cancel();

    _favSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _favouriteProducts = snapshot.docs.map((doc) {
            final Map<String, dynamic> data = doc.data();
            return {...data, 'docId': doc.id};
          }).toList();
        });
      }
    }, onError: (e) {
      debugPrint("Favorites Subscription Error: $e");
    });
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    super.dispose();
  }

  void _toggleFavourite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String name = (product['name'] ?? product['title'] ?? '').toString().trim();
    if (name.isEmpty) return;

    final existing = _favouriteProducts.firstWhere(
      (p) {
        final pName = (p['name'] ?? p['title'] ?? '').toString().trim();
        return pName == name || 
               (product['docId'] != null && p['docId'] == product['docId']) ||
               (product['id'] != null && p['docId'] == product['id']);
      },
      orElse: () => {},
    );

    final String favId = (existing['docId'] ?? product['docId'] ?? product['id'] ?? name.replaceAll(' ', '_')).toString().trim();

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(favId);

    try {
      final doc = await favRef.get();
      if (doc.exists) {
        await favRef.delete();
      } else {
        final Map<String, dynamic> favData = Map.from(product);
        favData['name'] = name;
        favData['title'] = name;
        final String img = (product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '').toString();
        favData['image'] = img;
        favData['imagePath'] = img;
        favData['imageUrl'] = img;

        if (favData['badgeColor'] is Color) {
          favData['badgeColor'] = (favData['badgeColor'] as Color).toARGB32();
        }

        favData['docId'] = favId;
        favData['isFavourite'] = true;
        favData['addedAt'] = FieldValue.serverTimestamp();

        await favRef.set(favData);
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
    // Clear notifications if Home (index 0), Orders (index 3) or Profile (index 4) is tapped
    if (index == 0 || index == 3 || index == 4) {
      _markNotificationsAsRead();
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryTeal),
              SizedBox(height: 15),
              Text("Securing session...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        userName: widget.userName,
        onCartTap: () => changeTab(2),
        onFavoritesTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyFavouritesScreen(
                onFavouriteToggle: _toggleFavourite,
              ),
            ),
          );
        },
        onCategoryTap: (String category) {
          setState(() {
            selectedCategory = category.isEmpty ? "All" : category;
            currentIndex = 1;
          });
        },
        favouriteProducts: _favouriteProducts,
        onFavouriteToggle: _toggleFavourite,
      ),

      CategoriesScreen(
        key: ValueKey(selectedCategory),
        initialCategory: selectedCategory,
        preLoadedCategories: _categories,
        externalFavouriteProducts: _favouriteProducts,
        onExternalFavouriteToggle: _toggleFavourite,
        onBackToHome: () => changeTab(0),
      ),

      CartScreen(
        onBackTap: () => changeTab(0),
      ),

      OrderScreen(
        onBackToHome: () => changeTab(0),
      ),

      ProfileScreen(
        userName: widget.userName,
        onBackToHome: () => changeTab(0),
        favouriteProducts: _favouriteProducts,
        allProducts: const [],
        favouriteNames:
        _favouriteProducts.map((p) => (p['name'] ?? p['title'] ?? '').toString()).toSet(),
        onFavouriteToggle: _toggleFavourite,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: screens[currentIndex],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_rounded, "Home", 0),
              navItem(Icons.grid_view_rounded, "Catalog", 1),
              navItem(Icons.shopping_cart_rounded, "Cart", 2),
              navItem(Icons.receipt_long_rounded, "Orders", 3),
              navItem(Icons.person_rounded, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryTeal.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryTeal : Colors.grey.shade400,
                ),
                if (!isSelected && (index == 0 || index == 3 || index == 4) && user != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('notifications')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              "${snapshot.data!.docs.length}",
                              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
