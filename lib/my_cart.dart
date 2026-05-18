import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, wq q
        centerTitle: false,
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Edit", style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                cartItem("assets/images/tomatoes.png", "Fresh Tomatoes", "120", "1 kg"),
                cartItem("assets/images/potato png.png", "Organic Potatoes", "80", "1 kg"),
                cartItem("assets/images/green cabbage.png", "Green Cabbage", "60", "1 pc"),
                cartItem("assets/images/milk png.png", "Farm Fresh Milk", "110", "1 Litre"),
              ],
            ),
          ),

          /// BILLING SECTION
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                billingRow("Subtotal", "Rs.370"),
                const SizedBox(height: 10),
                billingRow("Delivery fee", "Rs.40"),
                const Divider(height: 30, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Rs.410", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      "Proceed to checkout",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WIDGET FOR INDIVIDUAL CART ITEM
  Widget cartItem(String image, String title, String price, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xffF7F8F3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 15),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(unit, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Rs. $price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          // Quantity Controls & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
              ),
              Row(
                children: [
                  quantityBtn(Icons.remove),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("1", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  quantityBtn(Icons.add),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// HELPER FOR +/- BUTTONS
  Widget quantityBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: Colors.black),
    );
  }

  /// HELPER FOR BILLING ROWS
  Widget billingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}