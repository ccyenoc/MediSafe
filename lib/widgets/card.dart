import 'package:flutter/material.dart';
import '../colors/color.dart';

class CustomSectionBox extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  final VoidCallback? onAddPressed;

  const CustomSectionBox({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.royalBlue, width: 1.5),
          ),
          child: child,
        ),
      ],
    );
  }
}

class RemovableTag extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Color color;
  final VoidCallback? onRemove;

  const RemovableTag({
    super.key,
    required this.label,
    this.subLabel,
    required this.color,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.royalBlue, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (subLabel != null)
                Text(subLabel!, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.remove, size: 18),
          ),
        ],
      ),
    );
  }
}

class AddTagPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const AddTagPlaceholder({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Add", style: TextStyle(color: Colors.grey, fontSize: 13)),
            Icon(Icons.add, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}