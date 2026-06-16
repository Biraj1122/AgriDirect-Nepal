import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:+9779861509463');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendEmail() async {
    final Uri url = Uri.parse('mailto:support@agridirect.com?subject=Support Request&body=Hi AgriDirect Team,');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Contact Options
            Row(
              children: [
                Expanded(
                  child: contactCard(
                    Icons.call, 
                    "Call Us", 
                    "+977 9861509463",
                    onTap: _makeCall,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: contactCard(
                    Icons.email_outlined, 
                    "Email Us", 
                    "support@agridirect.com",
                    onTap: _sendEmail,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            faqItem("How do I track my order?", "You can track your order status in the 'Orders' tab on the navigation bar."),
            faqItem("Is the produce organic?", "Yes, we source directly from certified organic farms across Nepal."),
            faqItem("What are the delivery hours?", "We deliver from 7:00 AM to 7:00 PM every day in Kathmandu and Lalitpur."),
            faqItem("Can I cancel my order?", "Orders can be cancelled within 30 minutes of placement via the app."),
          ],
        ),
      ),
    );
  }

  Widget contactCard(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              subtitle, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget faqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}