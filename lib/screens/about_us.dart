import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Platform brand configuration
    const Color primaryFarmGreen = Color(0xFF2E7D32);
    const Color softBackground = Color(0xffF7F8F3);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "About AgriDirect Nepal",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero App Icon Container
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 70,
                  color: primaryFarmGreen,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "AgriDirect Nepal",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Our Vision
              _buildAboutCard(
                title: "Our Vision",
                icon: Icons.visibility_rounded,
                iconColor: primaryFarmGreen,
                child: const Text(
                  "AgriDirect Nepal is a modern tech initiative designed to bridge the gap between local Nepalese farmers and household consumers. By cutting out third-party wholesale networks, we ensure fresh farm produce reaches your kitchen table under fair, transparent trade terms.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Value Benchmarks
              _buildAboutCard(
                title: "Value Benchmarks",
                icon: Icons.verified_user_rounded,
                iconColor: primaryFarmGreen,
                child: Column(
                  children: [
                    _buildValueRow(
                      context,
                      title: "Direct Sourcing",
                      subtitle: "Sourced directly from local regions including Kavre Organic Farms, Himalayan Orchards, and Terai Produce.",
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    _buildValueRow(
                      context,
                      title: "Quality First",
                      subtitle: "Guaranteed listings detailing specific local farming methods, organic certifications, and fresh morning-picked options.",
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    _buildValueRow(
                      context,
                      title: "Precise Logistics",
                      subtitle: "Built-in mapping support to quickly track location data and safely calculate delivery ranges directly to your home address.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Footer Ownership Label
              Text(
                "© ${DateTime.now().year} FarmTech Group Project",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Card UI Construction Helper
  Widget _buildAboutCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // Value Bullet Entry Construction Helper
  Widget _buildValueRow(BuildContext context, {required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}