import 'dart:io';

import 'package:flutter/material.dart';

class PreviewImage extends StatefulWidget {
  const PreviewImage({super.key});

  @override
  State<PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  late final File _imageFile;

  @override
  Widget build(BuildContext context) {
    _imageFile = ModalRoute.of(context)?.settings.arguments as File;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded
                    ? child
                    : AnimatedOpacity(
                        opacity: frame != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: child,
                      ),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Error loading image',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              tooltip: 'Back',
              child: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
