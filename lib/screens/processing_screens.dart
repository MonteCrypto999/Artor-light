import 'package:flutter/material.dart';

import '/src/functions.dart';

class ProcessingScreen extends StatelessWidget {
  final int nbrImage;
  const ProcessingScreen({required this.nbrImage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          alignment: Alignment.center,
          child: FutureBuilder<void>(
              future: startCreating(nbrImage),
              builder: (c, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Génération terminée',
                      style: TextStyle(fontSize: 34.0),
                    ),
                    SizedBox(height: 30.0),
                    TextButton(
                      child: Text('Refaire'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                );
              })),
    );
  }
}
