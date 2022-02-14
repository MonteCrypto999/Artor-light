import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' show dirname;

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'config.dart';

import 'models/metadata_nft.dart';
import 'models/local_data.dart';

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
bool isMetadataExists = false;

final NumberFormat _formatter = NumberFormat("00000");

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  String toTitleCase() =>
      split(' ').map((str) => str.toCapitalized()).join(' ');
}

Future<void> saveImage(_editionCount) async {
  final _picture = recorder.endRecording();
  final _img = await _picture.toImage(width, height);
  final _encodePng = await _img.toByteData(format: ui.ImageByteFormat.png);

  if (_encodePng != null) {
    File('$dir/output/${_formatter.format(_editionCount)}.png')
        .writeAsBytesSync(_encodePng.buffer.asUint8List());
  } else {}
}

void addMetadata(String name, int edition) {
  final Map<String, dynamic> _attr = {};
  final String image = 'ipfs://$edition.png';

  final _editionWithDigits = _formatter.format(edition);
  String? type;
  if (attributesList.isNotEmpty) {
    for (var attr in attributesList) {
      if (attr.name == 'Base') {
        type = attr.attribute.value;
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
  List<int> randNum = [];

  for (var layer in data.layers) {
    List<int> _randElement = [];
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

    randNum.add(_randElementNum);
  }

  return randNum;
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

Future<void> checkMetaConfig() async {
  String _jsonFilePath = '$dir/meta.json';
  File _file = File(_jsonFilePath);

  if (await _file.exists()) {
    final _raw = await _file.readAsString();
    final _json = jsonDecode(_raw);

    if (_json != null) {
      metadataConfig = _json;
      isMetadataExists = true;
    } else {
      isMetadataExists = false;
    }
  } else {
    isMetadataExists = false;
  }
}

AttributeData Function(String path) getMetadataAttr(bool isConfigExists) {
  AttributeData getFromPath(String path) {
    final _baseName = path.split('\\').last.replaceAll('.png', '');
    final List _splitMeta = _baseName.split('-').first.split(".");
    _splitMeta.removeAt(0);
    final String? _meta = _splitMeta.join(" ").toTitleCase();

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

  if (_listDirLayers.isEmpty) {
    exit(0);
  }

  // String _dirId;
  AttributeData Function(String) getAttribute =
      getMetadataAttr(isMetadataExists);

  for (Directory layerDir in _listDirLayers) {
    // _dirId = getDirname(layerDir.path).split('-').first;
    final _name = getDirname(layerDir.path, symbol: '-');

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
      final _element = LayerElement(
          id: i,
          name: _name,
          attribute: _value,
          path: _path,
          weight: getWeight(_path));
      _layerElements.add(_element);
    }

    LayerData _layerData =
        LayerData(id: 0, name: _name, elements: _layerElements);
    layersData.add(_layerData);
  }
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

      await saveImage(editionCount);
      addMetadata(editionCount.toString(), editionCount);

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
