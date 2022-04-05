class MetadataNFT {
  final String assetName;
  final String name;
  final String project;
  String? policyID;
  String? description;
  String? base;
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
      this.base});

  Map<String, dynamic> toJson() => {
        "721": {
          policyID != null ? policyID : "<policy_id>": {
            assetName: {
              "project": project,
              "name": name,
              "image": image,
              "mediabase": "image/png",
              "attributes": attributes,
              "base": base
            }
          },
          "version": "1.0"
        }
      };
  Map<String, dynamic> toJsonFinal() {
    List<String> _layerSized = [
      'armleft',
      'armright',
      'shoulderleft',
      'shoulderright'
    ];

    attributes.updateAll((key, value) {
      if (_layerSized.contains(key.toLowerCase())) {
        List<String> _val = (value as String).split(" ");
        _val.removeLast();

        return _val.join(" ");
      } else {
        return value;
      }
    });

    return {
      "721": {
        policyID != null ? policyID : "<policy_id>": {
          assetName: {
            "project": project,
            "name": name,
            "image": image,
            "mediabase": "image/png",
            "attributes": attributes,
          }
        },
        "version": "1.0"
      }
    };
  }

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
        attributes: _asset[_assetName]["attributes"],
        base: _asset[_assetName]["base"]);
  }
  factory MetadataNFT.from(MetadataNFT metadata,
      {String? assetName,
      String? name,
      String? project,
      String? policyID,
      String? description,
      String? base,
      String? image,
      String? edition,
      Map<String, dynamic>? attributes}) {
    return MetadataNFT(
        assetName: assetName ?? metadata.assetName,
        name: name ?? metadata.name,
        project: project ?? metadata.project,
        image: image ?? metadata.image,
        edition: edition ?? metadata.edition,
        attributes: attributes ?? metadata.attributes);
  }
}

class LayerAttributesData {
  String name;
  List<AttributeData> attributes;

  LayerAttributesData(this.name, this.attributes);

  Map<String, dynamic> toJson() {
    if (attributes.length == 1) {
      return {name: attributes.first.value};
    }

    Map<String, Map<String, dynamic>> _temp = {};
    List<MapEntry<String, dynamic>> _tempList = [];
    for (var _attr in attributes) {
      _tempList.add(MapEntry(_attr.name!, _attr.value));
    }
    _temp[name] = {}..addEntries(Iterable.castFrom(_tempList));
    return _temp;
  }
}

class AttributeData {
  String? name;
  String value;

  AttributeData({this.name, required this.value});
}
