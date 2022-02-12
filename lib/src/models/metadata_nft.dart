class MetadataNFT {
  final String name;
  final String description;
  final String image;
  final int edition;
  final DateTime date;
  final List<LayerAttributesData> attributes;

  MetadataNFT({
    required this.name,
    this.description = '',
    required this.image,
    required this.edition,
    required this.date,
    required this.attributes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'image': image,
        'edition': edition,
        'date': date.toIso8601String(),
        'attributes': attributes.map((attr) => attr.toJson()).toList()
      };
}

class LayerAttributesData {
  String name;
  List<AttributeData> attributes;

  LayerAttributesData(this.name, this.attributes);

  Map<String, dynamic> toJson() {
    final _jsonAttributes = attributes.map((e) => e.toJson()).toList();

    return {name: _jsonAttributes};
  }
}

class AttributeData {
  String value;

  AttributeData(this.value);

  String toJson() => value;
}
