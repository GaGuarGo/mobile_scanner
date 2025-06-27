import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:cam_scanner_test/features/biometry/data/services/database_service.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    DatabaseService().initialize().then((_) {
      LogHelper.success('Database initialized successfully');
    }).catchError((error) {
      LogHelper.error('Error initializing database: $error');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: (){
                navigatorKey.currentState?.pushNamed('/scanner');
              },
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight * 0.5,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.0,
                    children: [
                      Icon(
                        Icons.scanner_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                      Text(
                        'Cam Scanner'.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: (){
                navigatorKey.currentState?.pushNamed('/faces');
              },
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.0,
                    children: [
                      Icon(
                        Icons.face_outlined,
                        color: Colors.black,
                        size: 48,
                      ),
                      Text(
                        'Face Biometry'.toUpperCase(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
