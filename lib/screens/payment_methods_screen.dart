import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double subtotal;
  final bool isCheckoutMode;
  final double? selectedLat; // Nullable for configuration safe modes
  final double? selectedLng; // Nullable for configuration safe modes

  const PaymentMethodsScreen({
    super.key,
    this.subtotal = 0.0,
    this.isCheckoutMode = false,
    this.selectedLat,
    this.selectedLng,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedMethod = 'cod';
  double _calculatedDistanceKm = 0.0;
  double _dynamicDeliveryCharge = 40.0;
  int _estimatedTimeMinutes = 25;

  @override
  void initState() {
    super.initState();
    _calculateShippingMetrics();
  }

  void _calculateShippingMetrics() {
    // Falls back safely to central Kathmandu coordinates if no geolocation parameters exist
    double lat = widget.selectedLat ?? 27.7172;
    double lng = widget.selectedLng ?? 85.3240;

    double storeLat = 27.7007; // Target warehouse coordinates
    double storeLng = 85.3166;

    double kDistance = ((lat - storeLat).abs() + (lng - storeLng).abs()) * 100;
    if (kDistance < 1.0) kDistance = 3.4;

    setState(() {
      _calculatedDistanceKm = double.parse(kDistance.toStringAsFixed(1));
      _dynamicDeliveryCharge = double.parse((40.0 + (_calculatedDistanceKm * 15)).toStringAsFixed(0));
      _estimatedTimeMinutes = (15 + (_calculatedDistanceKm * 2.5)).toInt();
    });
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xffEEF5E8),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 50),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Payment Successful!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your order has been authorized safely.\nDelivery ETA: $_estimatedTimeMinutes mins (${_calculatedDistanceKm}km)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Track Shipment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = widget.subtotal + _dynamicDeliveryCharge;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isCheckoutMode ? "Checkout Options" : "Payment Methods"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Payment Option", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 'cod'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: _selectedMethod == 'cod' ? Border.all(color: Colors.green, width: 2) : null,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: Colors.green),
                    const SizedBox(width: 15),
                    const Expanded(child: Text("Cash on Delivery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Icon(_selectedMethod == 'cod' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.green),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 'qr'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: _selectedMethod == 'qr' ? Border.all(color: Colors.green, width: 2) : null,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.green),
                        const SizedBox(width: 15),
                        const Expanded(child: Text("Scan & Pay (Fonepay / eSewa)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        Icon(_selectedMethod == 'qr' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.green),
                      ],
                    ),
                    if (_selectedMethod == 'qr') ...[
                      const Divider(height: 30),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xffEEF5E8), borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.qr_code_2, size: 180, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ONLY RENDERS DETAILS CARD IF ACTIVE CHECKOUT PARAMETER IS TRUE
            if (widget.isCheckoutMode) ...[
              const SizedBox(height: 30),
              const Text("Delivery Logistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bike, color: Colors.green),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Distance: $_calculatedDistanceKm km\nEst. Time: $_estimatedTimeMinutes mins",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal", style: TextStyle(color: Colors.grey, fontSize: 15)),
                        Text("Rs. ${widget.subtotal}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Dynamic Shipping Fee", style: TextStyle(color: Colors.grey, fontSize: 15)),
                        Text("Rs. $_dynamicDeliveryCharge", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                      ],
                    ),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Rs. $totalAmount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showSuccessPopup,
                  child: const Text("Confirm & Pay Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}