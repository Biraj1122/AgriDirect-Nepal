import 'package:flutter/material.dart';
import '../../utils/translations.dart';

class DiseaseLibraryScreen extends StatefulWidget {
  const DiseaseLibraryScreen({super.key});

  @override
  State<DiseaseLibraryScreen> createState() => _DiseaseLibraryScreenState();
}

class _DiseaseLibraryScreenState extends State<DiseaseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";
  bool _isNepali = false;

  final List<String> _categories = ["All", "Vegetables", "Fruits", "Livestock", "Grains"];

  String _getCategory(String key) {
    final k = key.toLowerCase();
    if (k.contains("poultry") || k.contains("cattle") || k.contains("goat") || k.contains("egg")) return "Livestock";
    if (k.contains("apple") || k.contains("mango") || k.contains("banana")) return "Fruits";
    if (k.contains("rice") || k.contains("maize")) return "Grains";
    if (k.contains("bitter gourd") || k.contains("ginger") || k.contains("turmeric") || k.contains("cabbage") || k.contains("cauliflower")) return "Vegetables";
    return "Grains"; // Default to Grains or another valid category instead of "Others" to avoid empty results if "Others" is not in _categories
  }

  @override
  Widget build(BuildContext context) {
    // Filter and prepare the list
    final List<MapEntry<String, Map<String, String>>> diseaseEntries = AppTranslations.diseaseData.entries.where((e) {
      final String key = e.key;
      if (key == "Healthy" || key == "Healthy Leaf") return false;
      
      final Map<String, String> data = e.value;
      final String category = _getCategory(key);
      
      final String query = _searchQuery.toLowerCase();
      final bool matchesSearch = key.toLowerCase().contains(query) ||
          (data['name_ne'] ?? "").contains(_searchQuery) ||
          (data['name_en'] ?? "").toLowerCase().contains(query);
          
      final bool matchesCat = _selectedCategory == "All" || category == _selectedCategory;
      
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text("Agri-Vet Library", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          Row(
            children: [
              const Text("EN", style: TextStyle(fontSize: 12)),
              Switch(
                value: _isNepali,
                onChanged: (val) => setState(() => _isNepali = val),
                activeThumbColor: Colors.green,
                activeTrackColor: Colors.green.withValues(alpha: 0.5),
              ),
              const Text("ने", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: diseaseEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: diseaseEntries.length,
                    itemBuilder: (context, index) {
                      final entry = diseaseEntries[index];
                      return _buildDiseaseCard(entry.key, _getCategory(entry.key));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: _isNepali ? "खोज्नुहोस् (उदा. धान, गाई, अदुवा)" : "Search (e.g. Rice, Cattle, Ginger)",
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_isNepali ? _translateCategory(cat) : cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 13),
                    backgroundColor: Colors.grey.shade200,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _translateCategory(String cat) {
    switch (cat) {
      case "All": return "सबै";
      case "Vegetables": return "तरकारी";
      case "Fruits": return "फलफूल";
      case "Livestock": return "पशुपन्छी";
      case "Grains": return "अन्नबाली";
      default: return cat;
    }
  }

  Widget _buildDiseaseCard(String key, String category) {
    final displayName = AppTranslations.translate(key, 'name_ne', isNepali: _isNepali);
    final displaySymptoms = AppTranslations.translate(key, 'symptoms_ne', isNepali: _isNepali);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: () => _showDiseaseDetails(key),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIconForCategory(category), color: Colors.green),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      displaySymptoms,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case "Vegetables": return Icons.grass;
      case "Fruits": return Icons.apple;
      case "Livestock": return Icons.pets;
      case "Grains": return Icons.agriculture;
      default: return Icons.eco;
    }
  }

  void _showDiseaseDetails(String key) {
    final displayName = AppTranslations.translate(key, 'name_ne', isNepali: _isNepali);
    final displaySymptoms = AppTranslations.translate(key, 'symptoms_ne', isNepali: _isNepali);
    final displayRemedy = AppTranslations.translate(key, 'remedy_ne', isNepali: _isNepali);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(height: 30),
              _buildInfoSection(_isNepali ? "मुख्य लक्षणहरू" : "Main Symptoms", displaySymptoms, Icons.warning_amber_rounded, Colors.orange),
              const SizedBox(height: 20),
              _buildInfoSection(_isNepali ? "उपचार विधि" : "Remedy / Treatment", displayRemedy, Icons.medical_services_outlined, Colors.blue),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isNepali ? "बन्द गर्नुहोस्" : "Close", style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_isNepali ? "कुनै नतिजा भेटिएन।" : "No matching records found.", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
