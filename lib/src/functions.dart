import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' show dirname;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'config.dart';

import 'models/metadata_nft.dart';
import 'models/local_data.dart';
import 'models/rule.dart';
import 'models/randomElement.dart';

late ui.PictureRecorder recorder;
late ui.Canvas nftCanvas;
final String dir = dirname(Platform.script.toFilePath());
String outputDir = '/output';
String projectName = "Project E.N.D";
String assetName = "ProjectEND";

List<MetadataNFT> metadataList = [];
List<LayerAttributesData> attributesList = [];
List<LayerData> layersData = [];
Map<String, dynamic>? metadataConfig;
Map<String, List>? metadataCompliance;
Map<int, Rule>? rules;
Map<String, dynamic>? config;
bool isMetadataExists = false;
bool isCheckActived = false;
bool haveConfig = false;
String logs = "";

final NumberFormat _formatter = NumberFormat("00000");

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  String toTitleCase() =>
      split(' ').map((str) => str.toCapitalized()).join(' ');
}

Future<String> saveImage(_editionCount) async {
  final _picture = recorder.endRecording();
  final _img = await _picture.toImage(width, height);
  final _encodePng = await _img.toByteData(format: ui.ImageByteFormat.png);

  if (_encodePng != null) {
    final _file = File('$dir/output/${_formatter.format(_editionCount)}.png');
    _file.writeAsBytesSync(_encodePng.buffer.asUint8List());
    if (haveConfig) {
      //TODO Make a button to Use this function after the generation
      return await uploadFiletoIPFS(_file);
    }

    return "OK";
  } else {
    return "";
  }
}

void addMetadata(String name, int edition, String ipfsHash) {
  final Map<String, dynamic> _attr = {};
  final String image = 'ipfs://$ipfsHash';

  final _editionWithDigits = _formatter.format(edition);
  String? type;
  if (attributesList.isNotEmpty) {
    for (var attr in attributesList) {
      String _filterType = 'Base';
      if (attr.name == _filterType) {
        type = attr.attribute.value.replaceAll(_filterType, "").trim();
        continue;
      }
      _attr[attr.name] = attr.attribute;
    }
  }
  MetadataNFT tempMetadata = MetadataNFT(
    assetName: assetName + _editionWithDigits,
    project: projectName,
    edition: _editionWithDigits,
    name: "$projectName #$_editionWithDigits",
    image: image,
    type: type,
    attributes: _attr,
  );
  saveMetaDataSingleFile(editionCount: edition, data: tempMetadata);

  metadataList.add(tempMetadata);
  attributesList = [];
}

Future<void> checkOutputDir({String dirName = '/output'}) async {
  if (dir != '/output') {
    outputDir = dirName;
  }

  bool exists = await Directory('$dir/$outputDir').exists();

  if (!exists) {
    await Directory('$dir/$outputDir').create();
  }
}

void addAttributes(LayerData layer) {
  LayerElement selectElement = layer.selectedElement!;
  final AttributeData value = selectElement.attribute;
  final LayerAttributesData _attribute =
      LayerAttributesData(selectElement.name, value);
  attributesList.add(_attribute);
}

class MyImageHolder {
  final ui.Image image;

  MyImageHolder(this.image);

  void draw(ui.Canvas canvas) {
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
  }

  void dispose() => image.dispose();
}

Future<ui.Image> loadLayerImg(LayerData layer) async {
  if (layer.selectedElement == null) {
    throw 'Erreur, selectedElement est null';
  }

  final Uint8List _file = File(layer.selectedElement!.path).readAsBytesSync();
  final Completer<ui.Image> _completer = Completer<ui.Image>();
  ui.decodeImageFromList(_file, (ui.Image img) => _completer.complete(img));

  return _completer.future;
}

Future<List<LayerData>> constructLayerToDna(dna, RaceData data) async {
  List<LayerData> listDnaToLayers = [];

  for (int index = 0; index < data.layers.length; index++) {
    LayerData layer = data.layers[index];
    LayerElement selectedElement =
        layer.elements.firstWhere((e) => e.id == dna[index]);
    layer.selectedElement = selectedElement;
    listDnaToLayers.add(layer);
    addAttributes(layer);

    ui.Image _tmp = await loadLayerImg(layer);
    final _holder = MyImageHolder(_tmp.clone());
    _holder.draw(nftCanvas);
    _holder.dispose();
  }

  return listDnaToLayers;
}

bool isDnaUnique(List<List<int>> dnaList, List dna) {
  var _object = dnaList.firstWhere((element) => element.join() == dna.join(),
      orElse: () => []);

  return _object.isEmpty ? true : false;
}

List<int> createDna(RaceData data) {
  List<RandomElement> randElements = [];
  List<int> _finalRandElements = [];

  for (var layer in data.layers) {
    List<int> _randElement = [];
    String _elementName;
    int _randElementNum;
    bool _rarity = layer.elements.any((element) => element.weight != 100);

    if (!_rarity) {
      _randElementNum = Random().nextInt(layer.elements.length);
    } else {
      for (var element in layer.elements) {
        for (int i = 0; i < element.weight; i++) {
          _randElement.add(element.id);
        }
      }
      _randElement.shuffle();
      _randElementNum = _randElement.first;
    }
    var _elementData =
        layer.elements.firstWhere((e) => e.id == _randElementNum);
    _elementName = _elementData.path
        .split("\\")
        .last
        .replaceAll(".png", "")
        .split("-")
        .first;

    String _matcher =
        layer.name.toLowerCase() + ":" + _elementName.toLowerCase();
    randElements.add(RandomElement(
        layerPosition: layer.id,
        element: _elementData,
        matcher: _matcher)); //TODO Finir la fonction, matcher
  }

  // Check Rules
  if (rules != null) {
    for (Rule rule in rules!.values) {
      for (RandomElement randomElement in randElements) {
        if (rule.condition.toLowerCase() == randomElement.matcher) {
          if (rule.res.isNotEmpty) {
            String _layerName = rule.res["layer_name"].toString().toLowerCase();
            List<String> _values = List<String>.from(rule.res["values"])
              ..forEach((e) => e.toLowerCase());

            RandomElement _elementChoiced = randElements.firstWhere((e) {
              return e.element.name.toLowerCase() == _layerName;
            });

            bool _isElementListed =
                _values.contains(_elementChoiced.matcher.split(":").last);

            if (!_isElementListed) {
              _values.shuffle();
              String _choosedValue = _values.first.toLowerCase();
              var _layerData = data.layers
                  .firstWhere((e) => e.name.toLowerCase() == _layerName);

              LayerElement _elementData = _layerData.elements.firstWhere((e) =>
                  e.path
                      .split("\\")
                      .last
                      .replaceAll(".png", "")
                      .split("-")
                      .first
                      .toLowerCase() ==
                  _choosedValue);

              int _randIndex = randElements.indexOf(_elementChoiced);
              randElements[_randIndex] = RandomElement(
                  layerPosition: _layerData.id,
                  element: _elementData,
                  matcher: _layerName + ":" + _choosedValue);
            }
          }
        }
      }
    }
  }
  _finalRandElements = randElements.map((e) => e.element.id).toList();
  return _finalRandElements;
}

void writeMetaData(_data) =>
    File("$dir/output/_metadata.json").writeAsStringSync(_data);

void saveMetaDataSingleFile(
    {required int editionCount, required MetadataNFT data}) {
  File('$dir/output/$editionCount.json')
      .writeAsStringSync(jsonEncode(data.toJsonCIP25()));
}

String getDirname(String path, {String? symbol}) {
  final String _pathBuilder = path.split('\\').last;

  if (symbol != null) {
    return _pathBuilder.split(symbol).last;
  } else {
    return _pathBuilder;
  }
}

Future<dynamic> readJsonFile(String fileName) async {
  String _jsonFilePath = '$dir/$fileName';
  File _file = File(_jsonFilePath);

  if (await _file.exists()) {
    final _raw = await _file.readAsString();
    final _json = json.decode(_raw);
    return _json;
  } else {
    return null;
  }
}

Future<void> checkConfigFiles() async {
  var _json = await readJsonFile('meta.json');

  if (_json != null) {
    metadataConfig = _json;
    isMetadataExists = true;
  } else {
    isMetadataExists = false;
  }

  _json = await readJsonFile('check.json');
  if (_json != null) {
    metadataCompliance = Map<String, List>.from(_json);
    isCheckActived = true;
  }

  _json = await readJsonFile('rules.json');
  if (_json != null) {
    rules = Map<String, dynamic>.from(_json).map((key, value) {
      var _tmpValues = Map<String, dynamic>.from(value);
      _tmpValues["id"] = key;
      return MapEntry(int.parse(key), Rule.fromJson(_tmpValues));
    });

    isCheckActived = true;
  }

  _json = await readJsonFile('config.json');

  if (_json != null) {
    config = _json;
    haveConfig = true;
  }
}

AttributeData Function(String path) getMetadataAttr(bool isConfigExists) {
  AttributeData getFromPath(String path) {
    final _baseName = path.split('\\').last.replaceAll('.png', '');
    final String? _meta = _baseName
        .split('-')
        .first
        .replaceAll(RegExp('[^A-Za-z0-9]'), " ")
        .toTitleCase();

    return AttributeData(_meta!);
  }

  AttributeData getFromConfigFile(String path) {
    final _key = path.split('\\').last.replaceAll('.png', '');
    final bool _contains = metadataConfig!.containsKey(_key);
    if (_contains) {
      return metadataConfig![_key];
    } else {
      return getFromPath(path);
    }
  }

  if (isConfigExists) {
    return getFromConfigFile;
  } else {
    return getFromPath;
  }
}

Future<void> scanFolder() async {
  final Directory _dir = Directory(dir);
  final List<FileSystemEntity> entities =
      await _dir.list(followLinks: false).toList();

  final List<Directory> _rawDirList = entities.whereType<Directory>().toList();

  final List<Directory> _listDirLayers =
      _rawDirList.where((dir) => getDirname(dir.path).contains('-')).toList();

  _listDirLayers.sort((a, b) {
    String elementADirname = getDirname(a.path).split(('-')).first;
    String elementBDirname = getDirname(b.path).split('-').first;

    int? _checkIntA = int.tryParse(elementADirname);
    int? _checkIntB = int.tryParse(elementBDirname);

    if (_checkIntA != null && _checkIntB != null) {
      return _checkIntA.compareTo(_checkIntB);
    }
    return elementADirname.compareTo(elementBDirname);
  });

  if (_listDirLayers.isEmpty) {
    exit(0);
  }

  // String _dirId;
  AttributeData Function(String) getAttribute =
      getMetadataAttr(isMetadataExists);

  for (Directory layerDir in _listDirLayers) {
    final _name = getDirname(layerDir.path, symbol: '-');
    final int _layerPosition =
        int.parse(layerDir.path.split("\\").last.split("-").first);

    int getWeight(String path) {
      const int _defaultWeight = 100;
      final _dataList = path.split('\\').last.replaceAll('.png', '').split('-');

      if (_dataList.length == 1) return _defaultWeight;

      final _parse = int.tryParse(_dataList.last);

      if (_parse != null) {
        if (_parse > 0 && _parse < 100) {
          return _parse;
        }
        return _defaultWeight;
      } else {
        return _defaultWeight;
      }
    }

    List<LayerElement> _layerElements = [];

    final List<File> _layerElementsData =
        (await layerDir.list(followLinks: false).toList())
            .whereType<File>()
            .toList();

    for (int i = 0; i < _layerElementsData.length; i++) {
      final _path = _layerElementsData[i].path;
      final _value = getAttribute(_path);
      final _rawValue =
          _path.split('\\').last.replaceAll('.png', '').split('-').first;

      if (isCheckActived) {
        if (metadataCompliance != null) {
          var _meta = metadataCompliance!.map((key, values) {
            var _key = key.toLowerCase();
            List _values = [];
            for (var value in values) {
              _values.add(value.toString().toLowerCase());
            }

            return MapEntry(_key, _values);
          });

          if (!_meta.containsKey(_name.toLowerCase())) {
            logs = logs +
                "Erreur : le layer ($_name) du $_path n\'est pas conforme.\n";
          } else if (!_meta[_name.toLowerCase()]!
              .contains(_rawValue.toLowerCase())) {
            logs = logs +
                "Erreur : les metadata du fichier $_path ne sont pas conformes. valeur: $_rawValue \n";
          }
        }
      }

      final _element = LayerElement(
          id: i,
          name: _name,
          attribute: _value,
          path: _path,
          weight: getWeight(_path));
      _layerElements.add(_element);
    }
    var logFile = File('$dir/logs.txt');
    if (await logFile.exists()) {
      logFile.writeAsStringSync("");
    }
    logFile.writeAsStringSync(logs);

    LayerData _layerData =
        LayerData(id: _layerPosition, name: _name, elements: _layerElements);
    layersData.add(_layerData);
  }
}

Future<dynamic> uploadFiletoIPFS(File file) async {
  if (!haveConfig) {
    throw 'Error: No config.json found, unable to upload file';
  } else if (!config!.containsKey("auth")) {
    throw 'Error: Unable to locate credentials in the config file';
  }

  var _credentials = config!["auth"];
  var _baseUrl = Uri.parse("https://ipfs.infura.io:5001/api/v0/add");
  var _bytes = file.readAsBytesSync();

  final _req = http.MultipartRequest("POST", _baseUrl);
  _req.headers.addAll({HttpHeaders.authorizationHeader: 'Basic $_credentials'});

  final _multipartFile = http.MultipartFile.fromBytes('file', _bytes,
      contentType: MediaType('image', 'png'));
  _req.files.add(_multipartFile);

  final _streamedResponse = await _req.send();
  if (_streamedResponse.statusCode != 200) {
    throw 'Error: Unable to upload the data';
  }
  final _response = await http.Response.fromStream(_streamedResponse);

  final _decode = json.decode(_response.body) as Map<String, dynamic>;
  print(_decode);
  return _decode["Hash"];
}

Future<void> startCreating(int endEditionAt) async {
  Stopwatch _executionTime = Stopwatch()..start();
  final String _raceName = dir.split('/').last..split('.').last;

  RaceData race = RaceData(
      name: _raceName,
      layers: layersData,
      editionFrom: 1,
      editionTo: endEditionAt);

  // writeMetaData("");
  int editionCount = startEditionFrom;
  List<List<int>> dnaList = [];

  while (editionCount <= endEditionAt) {
    var newDna = createDna(race);
    if (isDnaUnique(dnaList, newDna)) {
      recorder = ui.PictureRecorder();
      nftCanvas = ui.Canvas(recorder);

      await constructLayerToDna(newDna, race);

      String _ipfsHash = await saveImage(editionCount);
      if (_ipfsHash.isEmpty) {
        throw 'Error: ipfs hash invalid';
      }
      addMetadata(editionCount.toString(), editionCount, _ipfsHash);

      dnaList.add(newDna);
      editionCount++;
    } else {
      print("DNA exists!");
    }
  }
  // List _jsonMetadataList = metadataList.map((e) => e.toJson()).toList();
  // writeMetaData(jsonEncode(_jsonMetadataList));

  _executionTime.stop();
}
