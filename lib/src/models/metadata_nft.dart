class MetadataNFT {
  final String assetName;
  final String name;
  final String project;
  String? policyID;
  String? description;
  String? type;
  final String image;
  final int edition;
  final Map<String, dynamic> attributes;

  MetadataNFT(
      {required this.assetName,
      required this.name,
      required this.project,
      required this.image,
      required this.edition,
      required this.attributes,
      this.type});

  Map<String, dynamic> toJsonCIP25() => {
        "721": {
          policyID != null ? policyID : "null": {
            assetName: {
              "Project": project,
              "name": name,
              "image": image,
              "attributes": attributes,
              type != null ? "type" : type: ""
            }
          }
        }
      };
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
