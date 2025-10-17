import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class DropZoneHeader extends StatelessWidget {
  const DropZoneHeader({
    super.key,
    required this.hasContent,
    required this.onClear,
    required this.onLoadFile,
  });

  final bool hasContent;
  final VoidCallback onClear;
  final VoidCallback onLoadFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            spacing: 8,
            children: [
              Icon(IconsaxPlusLinear.folder_open, size: 20),
              Text(
                'Drop Zone',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                Flexible(
                  child: FilledButton.icon(
                    onPressed: onLoadFile,
                    icon: const Icon(
                      IconsaxPlusLinear.document_upload,
                      size: 16,
                    ),
                    label: const Text(
                      'Load File',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (hasContent)
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(
                        IconsaxPlusLinear.close_square,
                        size: 16,
                      ),
                      label: const Text(
                        'Clear',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
