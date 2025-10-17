import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class EmptyDropZoneContent extends StatelessWidget {
  const EmptyDropZoneContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.document_upload, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Drop files or data here',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Supports images, text, files, and more',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
