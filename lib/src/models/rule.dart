class Rule {
  int id;
  String condition;
  Map<String, dynamic> res;
  bool? include;

  Rule(
      {required this.id,
      required this.condition,
      required this.res,
      this.include});

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
      condition: json["if"],
      res: json["res"],
      id: int.parse(json["id"]),
      include: json["include"]);
}
