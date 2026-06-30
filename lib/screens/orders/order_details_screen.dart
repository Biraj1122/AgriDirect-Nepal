import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farmtech_agridirect/screens/orders/orders_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  static const Color accentGreen = Color(0xFF1D9E75);
  static const Color lightBg = Color(0xFFF8FAFC);

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5));
  }

  Widget _buildStatusCard(String status, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(status, style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w900, fontSize: 20)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: accentGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: accentGreen, size: 24),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 14),
              const SizedBox(width: 8),
              Text(DateFormat('MMMM d, yyyy • h:mm a').format(date), style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _partnerRow(IconData icon, String label, String value, String? uid, {Widget? trailing}) {
    return Row(
      children: [
        if (uid != null)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snap) {
              final img = snap.data?.data() as Map<String, dynamic>?;
              final url = img?['profileImageUrl'];
              return CircleAvatar(
                radius: 20,
                backgroundColor: accentGreen.withValues(alpha: 0.1),
                backgroundImage: (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
                child: (url == null || url.isEmpty) ? Icon(icon, color: accentGreen, size: 20) : null,
              );
            }
          )
        else
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade100,
            child: Icon(icon, color: Colors.grey.shade400, size: 20),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF1A1D25), fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPartnersCard(String farm, String? farmerId, String rider, String? riderId, dynamic riderPhone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _partnerRow(Icons.agriculture_rounded, "Farmer", farm, farmerId),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _partnerRow(
            Icons.delivery_dining_rounded, 
            "Rider", 
            rider, 
            riderId,
            trailing: riderPhone != null ? IconButton(
              onPressed: () => _makeCall(riderPhone.toString()),
              icon: const Icon(Icons.phone_in_talk_rounded, color: accentGreen, size: 18),
              style: IconButton.styleFrom(backgroundColor: accentGreen.withValues(alpha: 0.1), padding: const EdgeInsets.all(8)),
            ) : null
          ),
        ],
      ),
    );
  }

  Widget _logisticsRow(IconData icon, String label, String value, {Widget? trailing, bool isSmall = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: const Color(0xFF1A1D25), fontWeight: FontWeight.w700, fontSize: isSmall ? 13 : 15)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildLogisticsCard(String address) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: _logisticsRow(Icons.location_on_rounded, "Shipping To", address, isSmall: true),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.image_not_supported, color: Colors.grey);
      }
    } else {
      String assetPath = imagePath;
      if (assetPath.isNotEmpty && !assetPath.startsWith('assets/')) {
        assetPath = 'assets/images/$imagePath';
      }
      return Image.asset(assetPath.isEmpty ? 'assets/images/logo.png' : assetPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: accentGreen));
    }
  }

  Widget _buildModernItemTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 60, height: 60,
              color: lightBg,
              child: _buildProductImage(item['image']?.toString() ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text("${item['unit'] ?? ''} • Qty: ${item['quantity'] ?? 1}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text("Rs. ${item['price']}", style: const TextStyle(fontWeight: FontWeight.w900, color: accentGreen, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _billingRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500)),
        Text("Rs. ${amount.toStringAsFixed(2)}", style: TextStyle(color: isTotal ? accentGreen : color, fontSize: isTotal ? 22 : 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildBillingCard(double subtotal, double deliveryFee, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A1D25), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _billingRow("Subtotal", subtotal, Colors.white70),
          const SizedBox(height: 12),
          _billingRow("Delivery Fare", deliveryFee, Colors.white70),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10, height: 1)),
          _billingRow("Grand Total", total, Colors.white, isTotal: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = (order['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    final status = order['status']?.toString() ?? 'Pending';
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    
    final riderName = order['deliveryName'] ?? "Assigning...";
    final riderId = order['deliveryId'];
    final riderPhone = order['deliveryPhone'];
    
    final farmName = order['farmName'] ?? "AgriDirect Partner";
    final farmerId = order['farmerUid'];
    
    final address = order['deliveryAddress'] ?? "No address";
    final isActive = ['Pending Farmer', 'Farmer Accepted', 'Awaiting Pickup', 'Picked Up', 'On the way', 'Arrived', 'Confirm Received'].contains(status);

    return Scaffold(
      backgroundColor: lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text("Order Receipt", style: TextStyle(color: Color(0xFF1A1D25), fontWeight: FontWeight.w800, fontSize: 18)),
              centerTitle: true,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: lightBg,
                child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18), onPressed: () => Navigator.pop(context)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(status, date),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Fulfillment Partners"),
                  const SizedBox(height: 16),
                  _buildPartnersCard(farmName, farmerId, riderName, riderId, riderPhone),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Logistics"),
                  const SizedBox(height: 16),
                  _buildLogisticsCard(address),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Ordered Items"),
                  const SizedBox(height: 16),
                  ...items.map((item) => _buildModernItemTile(item as Map<String, dynamic>)),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Billing Details"),
                  const SizedBox(height: 16),
                  _buildBillingCard(subtotal, deliveryFee, total),
                  const SizedBox(height: 40),
                  if (isActive)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(orderId: order['id'])));
                        },
                        icon: const Icon(Icons.map_rounded, color: Colors.white),
                        label: const Text("Track Live Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
