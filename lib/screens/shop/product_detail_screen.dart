import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/cart_model.dart';
import '../../Success/shared_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isFavourite;
  final Function(Map<String, dynamic>) onToggleFavourite;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onToggleFavourite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: const Color(0xffF7F8F3),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      final map = widget.product.toMap();
                      map['badge'] = 'Fresh';
                      map['badgeColor'] = Colors.green.toARGB32();
                      map['farm'] = widget.product.farmName ?? 'Local Farm';
                      map['rating'] = 4.5;
                      widget.onToggleFavourite(map);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.isFavourite ? "Removed from Favourites" : "Added to Favourites"),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: widget.isFavourite ? Colors.black87 : Colors.redAccent,
                        ),
                      );
                    },
                    icon: Icon(
                      widget.isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: widget.product.id ?? widget.product.title,
                    child: SafeProductImage(
                      imageUrl: widget.product.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1D25),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.product.unit,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Rs. ${widget.product.price}",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1D9E75),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "About product",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D25),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.longDescription,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          if (widget.product.farmName != null)
                            Expanded(child: _infoCard(Icons.agriculture_rounded, "Source", widget.product.farmName!)),
                          if (widget.product.season != null) ...[
                            const SizedBox(width: 15),
                            Expanded(child: _infoCard(Icons.wb_sunny_rounded, "Season", widget.product.season!)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          _quantitySelector(),
                        ],
                      ),
                      const SizedBox(height: 120), // Spacing for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0), Colors.white, Colors.white],
                ),
              ),
              child: GradientButton(
                label: "Add to cart",
                icon: Icons.shopping_basket_rounded,
                isLoading: false,
                teal: const Color(0xFF1D9E75),
                blue: const Color(0xFF1565C0),
                onTap: () {
                  for (int i = 0; i < quantity; i++) {
                    cartModel.add(widget.product);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Added $quantity items to cart"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1D9E75),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (quantity > 1) setState(() => quantity--);
            },
            icon: const Icon(Icons.remove_rounded, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "$quantity",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => quantity++),
            icon: const Icon(Icons.add_rounded, color: Color(0xFF1D9E75)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
