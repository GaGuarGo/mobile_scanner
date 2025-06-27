import 'package:cam_scanner_test/features/biometry/controllers/faces_controller.dart';
import 'package:cam_scanner_test/features/biometry/widgets/user_face_tile.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FacesView extends StatefulWidget {
  const FacesView({super.key});

  @override
  State<FacesView> createState() => _FacesViewState();
}

class _FacesViewState extends State<FacesView> {
  late final FacesController _facesController;

  @override
  void initState() {
    _facesController = FacesController();
    _facesController.fetchFaces();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          ListenableBuilder(
              listenable: _facesController,
              builder: (context, _) {
                if (_facesController.faces.isEmpty) {
                  return SizedBox.shrink();
                }
                return FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: Colors.black,
                  tooltip: 'Match Face',
                  child: Icon(
                    Symbols.ar_on_you,
                    color: Colors.white,
                  ),
                );
              }),
          FloatingActionButton(
            key: const Key('add-face-button'),
            onPressed: () {
              navigatorKey.currentState?.pushNamed('/biometry');
            },
            backgroundColor: Colors.black,
            tooltip: 'Add Face',
            child: Icon(
              Icons.face_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('Faces'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
          listenable: FacesController(),
          builder: (context, _) {
            if (_facesController.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_facesController.faces.isEmpty) {
              return const Center(
                child: Text(
                  'No faces found!\nTry adding one in the button below.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView(
              children: _facesController.faces
                  .map((face) => UserFaceTile(
                      face: face,
                      ondDelete: () => _facesController.deleteFace(face)))
                  .toList(),
            );
          }),
    );
  }
}
