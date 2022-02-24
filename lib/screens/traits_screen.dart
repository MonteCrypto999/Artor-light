import 'package:flutter/material.dart';

import '/src/functions.dart';

import '../src/models/local_data.dart';

class TraitsScreen extends StatelessWidget {
  const TraitsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          alignment: Alignment.center,
          child: FutureBuilder<List<Trait>>(
              future: calculateTraits(),
              builder: (c, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                }
                if (snap.data!.isEmpty || snap.data == null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Pas de traits disponible.'),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Retour'))
                    ],
                  );
                }
                final List<Trait> _data = snap.data!;

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        child: Text('Exporter en fichier txt'),
                        onPressed: () async {
                          await exportTraitsToTxtFile(snap.data!);
                          showDialog(
                              context: context,
                              builder: (c) => SimpleDialog(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: Text(
                                              'Fichier enregistré sous traits.txt'),
                                        )
                                      ]));
                        },
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Retour')),
                      SizedBox(
                        height: 30,
                      ),
                      Expanded(
                        child: ListView.builder(
                            itemCount: snap.data!.length,
                            itemBuilder: (c, index) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SelectableText(_data[index].layer +
                                      ' | ' +
                                      _data[index].name +
                                      ' | ' +
                                      _data[index].count.toString()),
                                ],
                              );
                            }),
                      ),
                    ],
                  ),
                );
              })),
    );
  }
}
