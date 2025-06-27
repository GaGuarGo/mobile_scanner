import 'package:flutter/material.dart';

class SavingFaceLoading extends StatelessWidget {
  const SavingFaceLoading({super.key});

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
              'Saving face data...'.toUpperCase(),
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
