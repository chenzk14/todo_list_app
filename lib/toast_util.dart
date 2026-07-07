import 'package:flutter/material.dart';

void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(Duration(milliseconds: 1500), () {
    entry.remove();
  });
}