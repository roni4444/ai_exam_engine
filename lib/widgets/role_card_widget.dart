import 'package:flutter/material.dart';

class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({super.key, required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 255 * 0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}
