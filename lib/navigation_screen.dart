
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/my_cart.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';

class NavigationScreen extends StatefulWidget {

final String userName;

const NavigationScreen({
super.key,
required this.userName,
});

@override
State<NavigationScreen> createState() =>
_NavigationScreenState();
}

class _NavigationScreenState
extends State<NavigationScreen> {

int currentIndex = 0;

late final List<Widget> screens;

@override
void initState() {
super.initState();

screens = [

HomeScreen(
onCartTap: () => changeTab(2),
),

const CategoriesScreen(),

const CartScreen(),

const OrderScreen(),

ProfileScreen(
userName: widget.userName,
),
];
}

void changeTab(int index) {
setState(() {
currentIndex = index;
});
}

@override
Widget build(BuildContext context) {

return Scaffold(

/// BODY
body: IndexedStack(
index: currentIndex,
children: screens,
),

/// BOTTOM NAVIGATION
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
mainAxisAlignment:
MainAxisAlignment.spaceAround,

children: [

navItem(
icon: Icons.home_rounded,
label: "Home",
index: 0,
),

navItem(
icon: Icons.grid_view_rounded,
label: "Categories",
index: 1,
),

navItem(
icon: Icons.shopping_cart_rounded,
label: "Cart",
index: 2,
),

navItem(
icon: Icons.receipt_long_rounded,
label: "Orders",
index: 3,
),

navItem(
icon: Icons.person_rounded,
label: "Profile",
index: 4,
),
],
),
),
),
);
}

Widget navItem({
required IconData icon,
required String label,
required int index,
}) {

final bool isSelected =
currentIndex == index;

return InkWell(
borderRadius:
BorderRadius.circular(18),

onTap: () {
setState(() {
currentIndex = index;
});
},

child: AnimatedContainer(
duration:
const Duration(milliseconds: 250),

curve: Curves.easeInOut,

padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 8,
),

decoration: BoxDecoration(
color: isSelected
? Colors.green.withOpacity(.12)
    : Colors.transparent,

borderRadius:
BorderRadius.circular(18),
),

child: Column(
mainAxisSize: MainAxisSize.min,

children: [

AnimatedScale(
scale: isSelected ? 1.1 : 1,

duration:
const Duration(milliseconds: 250),

child: Icon(
icon,
size: 26,

color: isSelected
? Colors.green
    : Colors.grey,
),
),

const SizedBox(height: 4),

Text(
label,

style: TextStyle(
fontSize: 12,

color: isSelected
? Colors.green
    : Colors.grey,

fontWeight: isSelected
? FontWeight.bold
    : FontWeight.w500,
),
),
],
),
),
);
}
}
