import 'package:flutter/material.dart';
import '../cart_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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

              Expanded(
                child: cartModel.items.isEmpty
                    ? const Center(
                  child: Text("Cart is empty"),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: cartModel.items.length,

                  itemBuilder: (context, index) {
                    final product = cartModel.items[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                            onPressed: () {
                              cartModel.removeAt(index);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),

                child: Column(
                  children: [

                    billingRow("Subtotal",
                        "Rs. ${cartModel.subtotal}"),

                    billingRow("Delivery Fee",
                        "Rs. ${cartModel.deliveryFee}"),

                    const Divider(),

                    billingRow(
                      "Total",
                      "Rs. ${cartModel.total}",
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),

                        onPressed: () {},

                        child: const Text(
                          "Proceed to Checkout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget billingRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}