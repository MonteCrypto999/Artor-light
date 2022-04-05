import 'package:flutter/material.dart';

import '/src/functions.dart';

class IPFSScreen extends StatelessWidget {
  const IPFSScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          alignment: Alignment.center,
          child: FutureBuilder<void>(
              future: uploadAllFilestoIPFS(),
              builder: (c, snap) {
                String _message;
                if (snap.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                }

                if (snap.hasError) {
                  _message = 'Erreur, merci de réessayer plus tard';
                }

                _message = 'Chargement des fichiers IPFS terminés';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _message,
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
