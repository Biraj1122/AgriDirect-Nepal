import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  List<Map<String, dynamic>> cartItems = [
    {
      "image": "assets/images/tomato.png",
      "title": "Fresh Tomatoes",
      "unit": "1 kg",
      "price": 120,
      "qty": 1,
    },

    {
      "image": "assets/images/potato.png",
      "title": "Organic Potatoes",
      "unit": "1 kg",
      "price": 80,
      "qty": 1,
    },

    {
      "image": "assets/images/cabbage.png",
      "title": "Green Cabbage",
      "unit": "1 pc",
      "price": 60,
      "qty": 1,
    },

    {
      "image": "assets/images/milk.png",
      "title": "Farm Fresh Milk",
      "unit": "1 Litre",
      "price": 110,
      "qty": 1,
    },
  ];

  int get subtotal {
    int total = 0;

    for (var item in cartItems) {
      total += (item['price'] as int) * (item['qty'] as int);
    }

    return total;
  }

  int deliveryFee = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: "Categories",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Orders",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TITLE
              const SizedBox(height: 10),

              Text(
                "My Cart",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),

              const SizedBox(height: 15),

              Divider(
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: const [

                  Text(
                    "My Cart",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "Edit",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// CART LIST
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length + 1,

                  itemBuilder: (context, index) {

                    /// TOTAL CARD
                    if (index == cartItems.length) {
                      return totalCard();
                    }

                    final item = cartItems[index];

                    return cartItemCard(
                      index: index,
                      image: item['image'],
                      title: item['title'],
                      unit: item['unit'],
                      price: item['price'],
                      qty: item['qty'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CART ITEM CARD
  Widget cartItemCard({
    required int index,
    required String image,
    required String title,
    required String unit,
    required int price,
    required int qty,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [

          /// IMAGE
          Container(
            height: 100,
            width: 100,

            decoration: BoxDecoration(
              color: const Color(0xffF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Padding(
              padding: const EdgeInsets.all(8.0),

              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Rs. $price",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    /// MINUS
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (cartItems[index]['qty'] > 1) {
                            cartItems[index]['qty']--;
                          }
                        });
                      },

                      child: const Text(
                        "-",
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 22),

                    Text(
                      qty.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 22),

                    /// PLUS
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          cartItems[index]['qty']++;
                        });
                      },

                      child: const Text(
                        "+",
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// DELETE
          IconButton(
            onPressed: () {
              setState(() {
                cartItems.removeAt(index);
              });
            },

            icon: Icon(
              Icons.delete_outline,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// TOTAL CARD
  Widget totalCard() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [

          /// SUBTOTAL
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                "Subtotal",
                style: TextStyle(fontSize: 16),
              ),

              Text(
                "Rs.$subtotal",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// DELIVERY
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                "Delivery fee",
                style: TextStyle(fontSize: 16),
              ),

              Text(
                "Rs.$deliveryFee",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Divider(
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          /// TOTAL
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                "Total",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                "Rs.${subtotal + deliveryFee}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),

              onPressed: () {},

              child: const Text(
                "Proceed to checkout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}