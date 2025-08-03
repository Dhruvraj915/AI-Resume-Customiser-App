// resume_input_card.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ResumeInputCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ResumeInputCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Colors.indigo),
        title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
