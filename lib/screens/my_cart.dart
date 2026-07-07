import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import 'profile/payment_methods_screen.dart';
import 'misc/farm_osm_screen.dart';
import '../models/user_data.dart';
import '../Success/shared_widgets.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  const CartScreen({super.key, this.onBackTap});

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

    if (address == null || lat == null || lng == null) return;

    setState(() {
      selectedAddress = address.toString();
      selectedLat = (lat as num).toDouble();
      selectedLng = (lng as num).toDouble();
    });

    UserData.setAddress(address: selectedAddress, latitude: selectedLat!, longitude: selectedLng!);
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.onBackTap != null) {
      widget.onBackTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: ListenableBuilder(
        listenable: cartModel,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xffF8FAF8),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20), onPressed: _handleBack),
              title: const Text("My Cart", style: TextStyle(color: Color(0xFF1A1D25), fontWeight: FontWeight.w900)),
            ),
            body: Column(
              children: [
                _buildAddressBar(),
                Expanded(child: cartModel.items.isEmpty ? _buildEmptyCart() : _buildCartList()),
                if (cartModel.items.isNotEmpty) _buildBillingSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: _selectAddress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 20)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Delivery Address", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)), Text(selectedAddress, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text("Your cart is empty", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextButton(onPressed: _handleBack, child: const Text("Go shopping", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: cartModel.items.length,
      itemBuilder: (context, index) {
        final item = cartModel.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))]),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: SafeProductImage(imageUrl: item.product.image, width: 80, height: 80)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(item.product.unit, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("Rs. ${item.product.price}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => cartModel.removeAt(index)),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      _qtyBtn(Icons.remove_rounded, () => cartModel.decrement(index)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.w900))),
                      _qtyBtn(Icons.add_rounded, () => cartModel.increment(index)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: Colors.black87)));
  }

  Widget _buildBillingSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))]),
      child: Column(
        children: [
          _row("Subtotal", cartModel.subtotal),
          const SizedBox(height: 10),
          _row("Delivery Fee", cartModel.deliveryFee),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
          _row("Total Amount", cartModel.total, isTotal: true),
          const SizedBox(height: 25),
          GradientButton(
            label: "Proceed to Checkout",
            icon: Icons.check_circle_rounded,
            isLoading: false,
            teal: const Color(0xFF1D9E75),
            blue: const Color(0xFF1565C0),
            onTap: () {
              if (selectedAddress == "Select delivery address") {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a delivery address first"), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent));
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodsScreen(subtotal: cartModel.subtotal, deliveryFee: cartModel.deliveryFee, total: cartModel.total, selectedLat: selectedLat, selectedLng: selectedLng, isCheckout: true)));
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey.shade600, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600, fontSize: isTotal ? 18 : 15)),
        Text("Rs. ${val.toStringAsFixed(0)}", style: TextStyle(color: isTotal ? Colors.green : Colors.black87, fontWeight: FontWeight.w900, fontSize: isTotal ? 22 : 16)),
      ],
    );
  }
}
