import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category Display Order (BDD Simulation)', () {
    testWidgets('Priority categories appear first', (WidgetTester tester) async {
      // Mock category list
      final fetchedNames = ["Dairy", "Fruits", "Vegetables", "Grains"];
      
      // Sort logic (BDD Step: When I view the categories section)
      fetchedNames.sort((a, b) {
        final nameA = a.toLowerCase();
        final nameB = b.toLowerCase();
        if (nameA == 'vegetables') return -1;
        if (nameB == 'vegetables') return 1;
        if (nameA == 'fruits') return -1;
        if (nameB == 'fruits') return 1;
        return nameA.compareTo(nameB);
      });
      
      final displayList = ["All", ...fetchedNames];

      // BDD Step: Then I should see...
      expect(displayList[0], "All");
      expect(displayList[1], "Vegetables");
      expect(displayList[2], "Fruits");
      expect(displayList[3], "Dairy");
      expect(displayList[4], "Grains");
    });
  });
}
