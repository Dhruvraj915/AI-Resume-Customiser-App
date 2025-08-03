import 'package:flutter/material.dart';

class JobDescriptionInputCard extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final bool isMultiline;

  const JobDescriptionInputCard({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: isMultiline ? 5 : 1,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
