import 'package:flutter/material.dart';
import '../themes/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Center(child: Text(text, style: const TextStyle(fontSize: 18))),
      ),
    );
  }
}
