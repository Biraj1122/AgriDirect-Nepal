import 'package:flutter/material.dart';
import '../utils/translations.dart';

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

  final List<String> _categories = ["All", "Potato", "Tomato", "Rice", "Maize"];

  final List<Map<String, dynamic>> _diseases = [
    {
      "name": "Potato: Late Blight",
      "crop": "Potato",
      "symptoms": "Water-soaked spots on leaves, white fungal growth on undersides, rapid browning and shriveling.",
      "remedy": "Apply Mancozeb or Ridomil Gold. Ensure proper spacing for ventilation. Remove infected plants immediately.",
      "organic": "Spray with copper-based fungicides or use a mixture of baking soda and water.",
      "image": "assets/images/potato.png"
    },
    {
      "name": "Potato: Early Blight",
      "crop": "Potato",
      "symptoms": "Small, dark brown spots with concentric rings (target-like) on older leaves.",
      "remedy": "Foliar spray of Chlorothalonil. Maintain soil fertility.",
      "organic": "Crop rotation and removing crop debris after harvest.",
      "image": "assets/images/potato.png"
    },
    {
      "name": "Tomato: Bacterial Spot",
      "crop": "Tomato",
      "symptoms": "Small, dark, water-soaked spots on leaves and fruit. Spots may have a yellow halo.",
      "remedy": "Copper-based bactericides. Avoid overhead irrigation.",
      "organic": "Use certified disease-free seeds. Practice 3-year crop rotation.",
      "image": "assets/images/tomato.png"
    },
    {
      "name": "Tomato: Leaf Mold",
      "crop": "Tomato",
      "symptoms": "Pale greenish-yellow spots on upper leaf surfaces; olive-green velvety fungal growth on undersides.",
      "remedy": "Increase ventilation in greenhouses. Use resistant varieties.",
      "organic": "Reduce humidity and keep foliage dry.",
      "image": "assets/images/tomato.png"
    },
    {
      "name": "Rice: Brown Spot",
      "crop": "Rice",
      "symptoms": "Small, circular to oval brown spots with gray or whitish centers.",
      "remedy": "Apply potash fertilizer. Use seed treatment with Thiram.",
      "organic": "Ensure proper drainage and balanced soil nutrition.",
      "image": "assets/images/brown rice.png"
    },
    {
      "name": "Rice: Leaf Blast",
      "crop": "Rice",
      "symptoms": "Spindle-shaped spots with white to gray centers and brown borders.",
      "remedy": "Apply Tricyclazole or Carbendazim. Avoid excessive Nitrogen.",
      "organic": "Use resistant cultivars and burn infected straw.",
      "image": "assets/images/brown rice.png"
    },
    {
      "name": "Maize: Common Rust",
      "crop": "Maize",
      "symptoms": "Cinnamon-brown pustules on both leaf surfaces. Pustules turn black as the plant matures.",
      "remedy": "Fungicide sprays like Pyraclostrobin if detected early.",
      "organic": "Plant resistant hybrids. Early planting can sometimes bypass peak rust season.",
      "image": "assets/images/maize.png"
    },
    {
      "name": "Maize: Northern Leaf Blight",
      "crop": "Maize",
      "symptoms": "Long, cigar-shaped grayish-green or tan lesions.",
      "remedy": "Apply strobilurin or azoxystrobin fungicides.",
      "organic": "Deep plowing to bury crop residue and rotation with non-host crops.",
      "image": "assets/images/maize.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredDiseases = _diseases.where((d) {
      final matchesSearch = d['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == "All" || d['crop'] == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text("Disease Library", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            child: filteredDiseases.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDiseases.length,
                    itemBuilder: (context, index) => _buildDiseaseCard(filteredDiseases[index]),
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
              hintText: "Search diseases (e.g. Blight)",
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
                    label: Text(cat),
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

  Widget _buildDiseaseCard(Map<String, dynamic> disease) {
    final displayName = _isNepali 
        ? AppTranslations.translate(disease['name'], 'name_ne') 
        : disease['name'];
    final displaySymptoms = _isNepali 
        ? AppTranslations.translate(disease['name'], 'symptoms_ne') 
        : disease['symptoms'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDiseaseDetails(disease),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(disease['image'], fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      displaySymptoms,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(_isNepali ? "उपचार हेर्नुहोस्" : "View Solution", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No diseases found matching your criteria.", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showDiseaseDetails(Map<String, dynamic> disease) {
    final displayName = _isNepali 
        ? AppTranslations.translate(disease['name'], 'name_ne') 
        : disease['name'];
    final displaySymptoms = _isNepali 
        ? AppTranslations.translate(disease['name'], 'symptoms_ne') 
        : disease['symptoms'];
    final displayRemedy = _isNepali 
        ? AppTranslations.translate(disease['name'], 'remedy_ne') 
        : disease['remedy'];
    final displayOrganic = _isNepali 
        ? AppTranslations.translate(disease['name'], 'organic_ne') 
        : disease['organic'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Chip(label: Text(disease['crop']), backgroundColor: Colors.green.withValues(alpha: 0.1), labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(disease['image'], height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 25),
                    _buildSectionHeader(Icons.warning_amber_rounded, _isNepali ? "लक्षणहरू" : "Symptoms", Colors.orange),
                    const SizedBox(height: 8),
                    Text(displaySymptoms, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 25),
                    _buildSectionHeader(Icons.medication, _isNepali ? "रासायनिक उपचार" : "Chemical Treatment", Colors.blue),
                    const SizedBox(height: 8),
                    Text(displayRemedy, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 25),
                    _buildSectionHeader(Icons.eco, _isNepali ? "जैविक उपचार" : "Organic Remedy", Colors.green),
                    const SizedBox(height: 8),
                    Text(displayOrganic, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(_isNepali ? "बुझें" : "Got it", style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
