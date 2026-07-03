class MenuCategory {
  const MenuCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name};
}
