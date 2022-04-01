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
import 'models/random_element.dart';

late ui.PictureRecorder recorder;
late ui.Canvas nftCanvas;
final String dir = dirname(Platform.script.toFilePath());
String outputDir = '/output';
String projectName = "Project E.N.D";
String assetName = "ProjectEND";

List<MetadataNFT> metadataList = [];
List<LayerAttributesData> attributesList = [];
List<LayerData> layersData = [];
Map<String, List>? metadataCompliance;
Map<int, Rule>? rules;
Map<String, dynamic>? config;
List<File> metaFiles = [];
String? baseElement;
bool isCheckActived = false;
bool haveConfig = false;
bool checkSizeEnabled = false;
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
    // if (haveConfig) {
    //   return await uploadFiletoIPFS(_file);
    // }

    return "QmbBzNmmBZMqsrhuqLjnKeG1H5NeS515QrcevyBRSkryoy"; // TODO Change for the deployment
  } else {
    return "";
  }
}

void addMetadata(String name, int edition, String ipfsHash) async {
  final Map<String, dynamic> _attr = {};
  final String image = 'ipfs://$ipfsHash';

  final _editionWithDigits = _formatter.format(edition);
  String? base;
  if (attributesList.isNotEmpty) {
    for (var attr in attributesList) {
      String _filterBase = 'Base';
      if (attr.name.toLowerCase() == _filterBase.toLowerCase()) {
        base = attr.attributes.first.value.replaceAll(_filterBase, "").trim();
        continue;
      }

      final _attrValues = attr.toJson();

      if (_attrValues.entries.length == 1) {
        _attr[attr.name] = _attrValues.entries.first.value;
      } else {
        _attr[attr.name] = _attrValues;
      }
    }
  }
  MetadataNFT tempMetadata = MetadataNFT(
    assetName: assetName + _editionWithDigits,
    project: projectName,
    edition: _editionWithDigits,
    name: "$projectName #$_editionWithDigits",
    image: image,
    base: base,
    attributes: _attr,
  );
  saveMetaDataSingleFile(editionCount: edition, data: tempMetadata);
  // await uploadNFT(edition, tempMetadata);

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

void addAttributes(LayerData layer) async {
  LayerElement selectElement = layer.selectedElement!;
  final _fileName = selectElement.path.split('\\').last.replaceAll('.png', '');

  final _jsonFileName = '$_fileName.json';
  List<String> _constructPath = selectElement.path.split('\\');
  _constructPath.last = _jsonFileName;

  Map? _rawjsonFile =
      await readJsonFile(_constructPath.join('\\'), absolutePath: true);

  List<AttributeData> values = [];
  if (_rawjsonFile != null) {
    final _json = Map<String, dynamic>.from(_rawjsonFile);

    final _rawMetadata = MetadataNFT.fromJson(_json);
    values.add(AttributeData(name: 'Base', value: _rawMetadata.base!));

    for (var _attr in _rawMetadata.attributes.entries) {
      values.add(AttributeData(name: _attr.key, value: _attr.value));
    }
  } else {
    values.add(selectElement.attribute);
  }

  final LayerAttributesData _attribute =
      LayerAttributesData(selectElement.name, values);
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

LayerElement selectElementByRarity(List<LayerElement> elements) {
  List<int> _elementsID = [];

  for (var element in elements) {
    for (int i = 0; i < element.weight; i++) {
      _elementsID.add(element.id);
    }
  }
  _elementsID.shuffle();

  return elements.firstWhere((e) => e.id == _elementsID.first);
}

List<RandomElement> generateRandomElement(List<LayerData> layers) {
  List<RandomElement> tmpElements = [];

  for (var layer in layers) {
    String _elementName;
    int _randElementNum;
    bool _rarity = layer.elements.any((element) => element.weight != 100);

    if (!_rarity) {
      _randElementNum = Random().nextInt(layer.elements.length);
    } else {
      _randElementNum = selectElementByRarity(layer.elements).id;
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
    tmpElements.add(RandomElement(
        layerPosition: layer.id, element: _elementData, matcher: _matcher));
  }
  return tmpElements;
}

List<int> createDna(RaceData data) {
  List<RandomElement> tmpElements = [];

  List<RandomElement> randElements = [];
  List<int> _finalRandElements = [];

  tmpElements = generateRandomElement(data.layers);

  if (rules != null) {
    List<RandomElement> checkElements = applyRules(tmpElements, data.layers);

    final _tmpCheckSize =
        data.layers.where((element) => element.name.toLowerCase() == "head");

    // Temp Fix for Check Size issue
    if (_tmpCheckSize.isNotEmpty) {
      checkSizeEnabled = true;
    }

    if (checkSizeEnabled) {
      while (!checkSize(checkElements)) {
        final _list = generateRandomElement(data.layers);
        checkElements = applyRules(_list, data.layers);
      }
    }
    randElements = checkElements;
  } else {
    randElements = tmpElements;
  }
  _finalRandElements = randElements.map((e) => e.element.id).toList();
  return _finalRandElements;
}

List<LayerElement> generateListByRules(
    {required LayerData layerData,
    required String layerName,
    required List<String> values}) {
  List<LayerElement> _elementsList = [];

  for (String val in values) {
    final _e = layerData.elements.firstWhere((element) =>
        element.path
            .split("\\")
            .last
            .replaceAll(".png", "")
            .split("-")
            .first
            .toLowerCase() ==
        val);
    _elementsList.add(_e);
  }
  return _elementsList;
}

RandomElement getElementByRules(
    {required Rule rule,
    required List<RandomElement> randElements,
    required String layerName}) {
  RandomElement _elementChoiced = randElements.firstWhere((e) {
    return e.element.name.toLowerCase() == layerName;
  });
  return _elementChoiced;
}

bool matchRule(List<String> ruleValues, RandomElement elementChoiced) {
  return ruleValues.contains(elementChoiced.matcher.split(":").last);
}

bool checkSize(List<RandomElement> randElements) {
  List<String> _size = ['s', 'l', 'm', 'xl'];
  List<String> _layerSized = [
    'armleft',
    'armright',
    'shoulderleft',
    'shoulderright'
  ];
  late String size;

  bool _isSized = true;
  List<RandomElement> dataSized = randElements
      .where((e) => _layerSized.contains(e.matcher.split(':').first))
      .toList();

  dataSized.firstWhere((data) {
    size = data.element.path
        .split("\\")
        .last
        .replaceAll(".png", "")
        .split("-")
        .first
        .split('_')
        .last
        .toLowerCase();

    return _size.contains(size);
  });

  for (RandomElement randomElement in dataSized) {
    String _actualSize = randomElement.element.path
        .split("\\")
        .last
        .replaceAll(".png", "")
        .split("-")
        .first
        .split('_')
        .last
        .toLowerCase();
    if (size != _actualSize) {
      _isSized = false;
    }
  }
  return _isSized;
}

List<RandomElement> applyRules(
    List<RandomElement> randElements, List<LayerData> layers) {
  List<RandomElement> elements = randElements.toList();

  for (RandomElement randomElement in randElements) {
    for (Rule rule in rules!.values) {
      if (rule.condition.toLowerCase() == randomElement.matcher) {
        if (rule.res.isNotEmpty) {
          List<String> _values = List<String>.from(rule.res["values"])
              .map((e) => e.toLowerCase())
              .toList();
          String _layerName = rule.res["layer_name"].toString().toLowerCase();

          RandomElement _elementChoiced = getElementByRules(
              rule: rule, randElements: randElements, layerName: _layerName);
          bool _isElementListed = matchRule(_values, _elementChoiced);

          if (!_isElementListed) {
            LayerData _layerData =
                layers.firstWhere((e) => e.name.toLowerCase() == _layerName);
            List<LayerElement> _elementsList = generateListByRules(
                layerData: _layerData, layerName: _layerName, values: _values);

            if (_elementsList.isEmpty) {
              throw 'Error: elementList is empty while choosing rarity by rules';
            }

            LayerElement _elementData = selectElementByRarity(_elementsList);

            int _randIndex = randElements.indexOf(_elementChoiced);
            elements[_randIndex] = RandomElement(
                layerPosition: _layerData.id,
                element: _elementData,
                matcher: _layerName +
                    ":" +
                    _elementData.path
                        .split("\\")
                        .last
                        .replaceAll(".png", "")
                        .split("-")
                        .first
                        .toLowerCase());
          }
        }
      }
    }
  }
  return elements;
}

void writeMetaData(_data) =>
    File("$dir/output/_metadata.json").writeAsStringSync(_data);

void saveMetaDataSingleFile(
    {required int editionCount, required MetadataNFT data}) {
  Map _jsonRaw;

  List<String> _size = ['s', 'l', 'm', 'xl'];
  List<String> _layerSized = [
    'armleft',
    'armright',
    'shoulderleft',
    'shoulderright'
  ];

  if (data.attributes.containsKey("Head")) {
    _jsonRaw = data.toJsonFinal();
  } else {
    _jsonRaw = data.toJson();
  }

  File('$dir/output/$editionCount.json')
      .writeAsStringSync(jsonEncode(_jsonRaw));
}

String getDirname(String path, {String? symbol}) {
  final String _pathBuilder = path.split('\\').last;

  if (symbol != null) {
    return _pathBuilder.split(symbol).last;
  } else {
    return _pathBuilder;
  }
}

Future<dynamic> readJsonFile(String fileName,
    {bool absolutePath = false}) async {
  String _jsonFilePath = absolutePath ? fileName : '$dir/$fileName';
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

AttributeData getMetadataAttr(String path) {
  final _baseName = path.split('\\').last.replaceAll('.png', '');
  final String? _meta = _baseName
      .split('-')
      .first
      .replaceAll('.', '999')
      .replaceAll(RegExp('[^A-Za-z0-9]'), " ")
      .replaceAll('999', '.')
      .toTitleCase();

  return AttributeData(value: _meta!);
}

Future<List<Trait>> calculateTraits() async {
  late List<MetadataNFT> _rawMetafile = [];
  final List<MetadataNFT> _cachedList = [];
  final List<Trait> traits = [];

  final _metaFileFinal = File('$dir/output/_metadata.json');
  if (await _metaFileFinal.exists()) {
    _cachedList.clear();
    final _raw = await _metaFileFinal.readAsString();
    final _json = List<Map<String, dynamic>>.from(json.decode(_raw));

    for (var _jsonData in _json) {
      final _metaDataTmp = MetadataNFT.fromJson(_jsonData);
      _cachedList.add(_metaDataTmp);
    }
    _rawMetafile = _cachedList;
  }
  if (_rawMetafile.isNotEmpty) {
    for (var _meta in _rawMetafile) {
      for (var _attr in _meta.attributes.entries) {
        if (traits.isNotEmpty) {
          bool _f(e) => e.layer == _attr.key && e.name == _attr.value;
          if (traits.any(_f)) {
            final _traitListed = traits[traits.indexWhere(_f)];
            _traitListed.count = _traitListed.count + 1;
            traits[traits.indexWhere(_f)] = _traitListed;
            continue;
          }
        }
        if (_attr.key == "Head") {
          for (var _rawTrait in (_attr.value as Map).entries) {
            final _tmpTrait =
                Trait(name: _rawTrait.value, layer: _rawTrait.key);
            traits.add(_tmpTrait);
          }
        } else {
          final _tmpTrait = Trait(name: _attr.value, layer: _attr.key);
          traits.add(_tmpTrait);
        }
      }
    }
  }

  traits.sort((a, b) => b.count.compareTo(a.count));

  return traits;
}

Future<void> exportTraitsToTxtFile(List<Trait> traits,
    {String filename = 'traits.txt'}) async {
  final _file = File('$dir/output/$filename');
  String data = traits
      .map((e) => e.layer + ' | ' + e.name + ' | ' + e.count.toString())
      .toList()
      .join("\n");

  _file.writeAsString(data);
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

  metaFiles = entities
      .where((element) => element.path.contains('_metadata') && element is File)
      .toList()
      .cast();
  // String _dirId;

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

    int _counter = 0;
    for (var rawLayerElement in _layerElementsData) {
      final _path = rawLayerElement.path;
      final _value = getMetadataAttr(_path);
      final _fileName = _path.split('\\').last;

      if (!_fileName.toLowerCase().contains('.png')) {
        continue;
      }

      final _rawValue = _fileName.replaceAll('.png', '').split('-').first;

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
                "Erreur : le layer ($_name) du $_path n'est pas conforme.\n";
          } else if (!_meta[_name.toLowerCase()]!
              .contains(_rawValue.toLowerCase())) {
            logs = logs +
                "Erreur : les metadata du fichier $_path ne sont pas conformes. valeur: $_rawValue \n";
          }
        }
      }

      final _element = LayerElement(
          id: _counter,
          name: _name,
          attribute: _value,
          path: _path,
          weight: getWeight(_path));
      _layerElements.add(_element);
      _counter++;
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

Future<void> uploadNFT(int edition, MetadataNFT metadata) async {
  if (!haveConfig) {
    throw 'Error: Cant upload without config json file';
  } else if (!config!.containsKey("nft_maker")) {
    throw 'Error: config file dont contains nftMaker Fields';
  }
  var _apiKey = config!["nft_maker"]["api_key"];
  var _projectID = config!["nft_maker"]["project_id"];
  var _baseUri = Uri.parse(
      'http://api-testnet.nft-maker.io/UploadNft/$_apiKey/$_projectID');

  Map<String, dynamic> _dataNFT = {
    "assetName": metadata.assetName,
    "previewImageNft": {
      "mimetype": "image/png",
      "fileFromIPFS": metadata.image,
      "displayname": metadata.name,
    },
    "metadata": json.encode(metadata.toJson())
  };
  var _body = json.encode(_dataNFT);
  var _contenType = {"Content-Type": "application/json"};
  var _response = await http.post(_baseUri, body: _body, headers: _contenType);

  if (_response.statusCode != 200) {
    throw 'Error: Metadata cant be uploaded. logs: ${_response.body}';
  }

  var _decode = json.decode(_response.body);
  print(_decode);
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
  List _jsonMetadataList = metadataList.map((e) => e.toJson()).toList();
  writeMetaData(jsonEncode(_jsonMetadataList));

  _executionTime.stop();
}
