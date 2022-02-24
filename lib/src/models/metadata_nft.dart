class MetadataNFT {
  final String assetName;
  final String name;
  final String project;
  String? policyID;
  String? description;
  String? type;
  final String image;
  final String edition;
  final Map<String, dynamic> attributes;

  MetadataNFT(
      {required this.assetName,
      required this.name,
      required this.project,
      required this.image,
      required this.edition,
      required this.attributes,
      this.type});

  Map<String, dynamic> toJson() => {
        "721": {
          policyID != null ? policyID : "<policy_id>": {
            assetName: {
              "project": project,
              "name": name,
              "image": image,
              "mediaType": "image/png",
              "attributes": attributes,
              "type": type
            }
          },
          "version": "1.0"
        }
      };
  factory MetadataNFT.fromJson(Map<String, dynamic> json) {
    final _asset = (json["721"] as Map<String, dynamic>).entries.first.value
        as Map<String, dynamic>;
    final String _assetName = _asset.keys.first;
    final String _edition = _assetName.split('#').last;

    return MetadataNFT(
        assetName: _assetName,
        name: _asset[_assetName]["name"],
        project: _asset[_assetName]["project"],
        image: _asset[_assetName]["image"],
        edition: _edition,
        attributes: _asset[_assetName]["attributes"]);
  }
}

class LayerAttributesData {
  String name;
  AttributeData attribute;

  LayerAttributesData(this.name, this.attribute);

  Map<String, dynamic> toJson() {
    return {name: attribute.toJson()};
  }
}

class AttributeData {
  String value;

  AttributeData(this.value);

  String toJson() => value;
}
