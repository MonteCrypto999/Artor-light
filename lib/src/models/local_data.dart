import 'package:artor_flutter/src/models/metadata_nft.dart';

const defaultWidth = 3352;
const defaultHeight = 3755;

class Position {
  final double x;
  final double y;
  const Position([this.x = 0, this.y = 0]);
}

class RaceData {
  final String name;
  final List<LayerData> layers;
  final int editionFrom;
  final int editionTo;

  RaceData(
      {required this.name,
      required this.layers,
      required this.editionFrom,
      required this.editionTo});
}

class LayerData {
  final int id;
  final String name;
  List<LayerElement> elements;
  LayerElement? selectedElement;
  final Position position;
  final int width;
  final int height;

  LayerData(
      {required this.id,
      required this.name,
      required this.elements,
      this.selectedElement,
      this.position = const Position(0, 0),
      this.width = defaultWidth,
      this.height = defaultHeight});
}

class LayerElement {
  final int id;
  final String name;
  final AttributeData attribute;
  final String path;
  final int weight;
  final bool hasJSONFile;

  LayerElement({
    required this.id,
    required this.name,
    required this.path,
    required this.attribute,
    this.hasJSONFile = false,
    this.weight = 100,
  });
}

class Trait {
  final String name;
  final String layer;
  int count;

  Trait({required this.name, required this.layer, this.count = 1});
}
