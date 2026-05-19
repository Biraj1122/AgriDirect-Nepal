import 'package:flutter/material.dart';
import 'farm_osm_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // State variables initialized with your default layout value
  String _displayAddress = "Baneshwor, Kathmandu, Nepal";

  // Method to handle navigation and capture data sent from Map Screen
  Future<void> _selectNewLocation() async {
    final Map<String, dynamic>? selectedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmOsmScreen(),
      ),
    );

    // If data was picked and confirmed, update the view state cleanly
    if (selectedData != null && selectedData['address'] != null) {
      setState(() {
        _displayAddress = selectedData['address'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Order",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ORDER STATUS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Order #45892",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text("Estimated Delivery", style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 3),
                          Text(
                            "25 mins",
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      trackingStep(Icons.receipt_long, "Order\nPlaced", true),
                      trackingLine(true),
                      trackingStep(Icons.shopping_bag, "Packed", true),
                      trackingLine(true),
                      trackingStep(Icons.local_shipping, "On The\nWay", true),
                      trackingLine(false),
                      trackingStep(Icons.home, "Delivered", false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// DYNAMIC DELIVERY ADDRESS CARD
            const Text(
              "Delivery Address",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _selectNewLocation, // Triggering mapping workflow
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffEEF5E8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.green),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivery Destination",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _displayAddress, // Dynamic variable string rendering
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            /// ORDER ITEMS
            const Text("Order Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            orderItem("assets/images/tomatoes.png", "Fresh Tomatoes", "1 kg", "120", "2"),
            orderItem("assets/images/potato png.png", "Organic Potatoes", "1 kg", "80", "1"),
            orderItem("assets/images/milk png.png", "Farm Fresh Milk", "1 L", "110", "1"),
            const SizedBox(height: 25),

            /// PAYMENT METHOD
            const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.payments_outlined, color: Colors.green),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cash on Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Pay when order arrives", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// SUMMARY CONTAINER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  summaryRow("Subtotal", "Rs.430"),
                  const SizedBox(height: 10),
                  summaryRow("Delivery Fee", "Rs.40"),
                  const SizedBox(height: 10),
                  summaryRow("Discount", "- Rs.20"),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Rs.450", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// BOTTOM ACTIONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text("Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text("Call Rider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget trackingStep(IconData icon, String title, bool active) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: active ? Colors.white : Colors.white24, shape: BoxShape.circle),
          child: Icon(icon, color: active ? Colors.green : Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget trackingLine(bool active) {
    return Expanded(
      child: Container(margin: const EdgeInsets.only(bottom: 28), height: 3, color: active ? Colors.white : Colors.white24),
    );
  }

  Widget orderItem(String image, String title, String unit, String price, String qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xffF7F8F3), borderRadius: BorderRadius.circular(18)),
            child: Image.asset(image),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(unit, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Rs. $price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xffEEF5E8), borderRadius: BorderRadius.circular(12)),
            child: Text("x$qty", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}