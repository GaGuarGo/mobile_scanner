import 'package:flutter/material.dart';

class SavingFaceLoading extends StatelessWidget {
  final String? message;
  const SavingFaceLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children: [
            Text(
              (message ?? 'Saving face data...').toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 6.0,
            ),
          ],
        ),
      ),
    );
  }
}
