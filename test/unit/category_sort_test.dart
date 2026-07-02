import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category Sorting Logic (TDD)', () {
    test('Categories should be sorted: Vegetables, Fruits, then Alphabetical', () {
      final input = ['pulses', 'fruits', 'vegetables', 'dairy', 'grains'];
      
      input.sort((a, b) {
        final nameA = a.toLowerCase();
        final nameB = b.toLowerCase();
        
        if (nameA == 'vegetables') return -1;
        if (nameB == 'vegetables') return 1;
        if (nameA == 'fruits') return -1;
        if (nameB == 'fruits') return 1;
        
        return nameA.compareTo(nameB);
      });

      expect(input[0], 'vegetables');
      expect(input[1], 'fruits');
      expect(input[2], 'dairy');
      expect(input[3], 'grains');
      expect(input[4], 'pulses');
    });
  });
}
