import 'dart:io';

import 'package:cam_scanner_test/features/biometry/data/models/face_model.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserFaceTile extends StatelessWidget {
  final void Function() ondDelete;
  final FaceModel face;
  const UserFaceTile({super.key, required this.face, required this.ondDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: face.photoPath == null
          ? Icon(
              Icons.face_4,
              color: Colors.black,
            )
          : InkWell(
              child: Hero(
                tag: 'preview-face-photo',
                child: CircleAvatar(
                    backgroundImage: FileImage(File(face.photoPath!))),
              ),
              onTap: () {
                navigatorKey.currentState?.pushNamed('/preview-image',
                    arguments: File(face.photoPath!));
              },
            ),
      title: Text(face.username ?? 'Unknown User'),
      subtitle: Text(
        'Created at: ${DateFormat('dd/MM/yyyy - HH:mm').format(face.createdAt!)}',
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete_outline_outlined,
          color: Colors.redAccent,
        ),
        tooltip: 'Delete Face',
        onPressed: ondDelete,
      ),
    );
  }
}
