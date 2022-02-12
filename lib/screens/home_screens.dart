import 'package:artor_flutter/screens/processing_screens.dart';
import 'package:flutter/material.dart';

import 'components/title_component.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(child: BuildForm());
  }
}

class BuildForm extends StatelessWidget {
  const BuildForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> _formK = GlobalKey();

    int _nbrImage = 5;

    return Form(
      key: _formK,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ComponentTitle(),
          SizedBox(
            height: 30.0,
          ),
          SizedBox(
            width: 250,
            child: TextFormField(
              keyboardType: TextInputType.numberWithOptions(
                  signed: false, decimal: false),
              onSaved: (value) {
                String _tmpVal = value!;
                if (_tmpVal.contains('-')) {
                  _tmpVal = _tmpVal.substring(1);
                }
                _nbrImage = int.parse(_tmpVal);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le champs ne peut rester vide';
                }
                if (!value.contains(RegExp(r'^(?:-?(?:0|[1-9][0-9]*))$'))) {
                  return 'Le champs doit contenir uniquement des chiffres';
                }
                return null;
              },
              initialValue: _nbrImage.toString(),
              decoration: InputDecoration(labelText: "Nbre d'image"),
            ),
          ),
          SizedBox(
            height: 30.0,
          ),
          TextButton(
            onPressed: () {
              if (_formK.currentState!.validate()) {
                _formK.currentState!.save();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProcessingScreen(nbrImage: _nbrImage)));
              }
            },
            child: Text(
              'Générer',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
