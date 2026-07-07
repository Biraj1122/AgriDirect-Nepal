import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleBackExitWrapper extends StatefulWidget {
  final Widget child;
  const DoubleBackExitWrapper({super.key, required this.child});

  @override
  State<DoubleBackExitWrapper> createState() => _DoubleBackExitWrapperState();
}

class _DoubleBackExitWrapperState extends State<DoubleBackExitWrapper> {
  DateTime? lastPressed;

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Exit App?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to close AgriDirect?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Exit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (lastPressed == null || now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Press back again to exit"),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        await _showExitDialog();
      },
      child: widget.child,
    );
  }
}
