import 'package:flutter/material.dart';
import '../cart_model.dart';
import '../payment_methods_screen.dart';
import '../farm_osm_screen.dart';
import '../user_data.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const CartScreen({
    super.key,
    this.onBackTap,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String selectedAddress = "Select delivery address";
  double? selectedLat;
  double? selectedLng;

  @override
  void initState() {
    super.initState();

    if (UserData.defaultAddress != null) {
      selectedAddress = UserData.defaultAddress!;
      selectedLat = UserData.defaultLat;
      selectedLng = UserData.defaultLng;
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result == null) return;

    final address = result["address"];
    final lat = result["lat"];
    final lng = result["lng"];

    if (address == null || lat == null || lng == null) {
      return;
    }

    setState(() {
      selectedAddress = address.toString();
      selectedLat = (lat as num).toDouble();
      selectedLng = (lng as num).toDouble();
    });

    UserData.setAddress(
      address: selectedAddress,
      latitude: selectedLat!,
      longitude: selectedLng!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xffF7F8F3),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (widget.onBackTap != null) {
                  widget.onBackTap!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              "My Cart",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(selectedAddress)),
                      TextButton(
                        onPressed: _selectAddress,
                        child: const Text("Change"),
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: cartModel.items.isEmpty
                    ? const Center(child: Text("Cart is empty"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: cartModel.items.length,
                        itemBuilder: (context, index) {
                          final product = cartModel.items[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  product.image,
                                  height: 70,
                                  width: 70,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(product.unit),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Rs. ${product.price}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      cartModel.removeAt(index),
                                )
                              ],
                            ),
                          );
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    _row("Subtotal", cartModel.subtotal),
                    _row("Delivery", cartModel.deliveryFee),
                    const Divider(),
                    _row("Total", cartModel.total, bold: true),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedAddress ==
                              "Select delivery address") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Select delivery address first",
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentMethodsScreen(
                                subtotal: cartModel.subtotal,
                                deliveryFee: cartModel.deliveryFee,
                                total: cartModel.total,
                                selectedLat: selectedLat,
                                selectedLng: selectedLng,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _row(String title, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          "Rs. ${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}