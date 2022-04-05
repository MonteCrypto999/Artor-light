import 'package:flutter/material.dart';

import '/src/functions.dart';

class NFTSScreen extends StatelessWidget {
  const NFTSScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          alignment: Alignment.center,
          child: FutureBuilder<void>(
              future: uploadAllNFTS(),
              builder: (c, snap) {
                String _message;
                if (snap.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                }

                if (snap.hasError) {
                  _message = 'Erreur, merci de réessayer plus tard';
                }

                _message = 'Chargement des NFTS terminés';
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
