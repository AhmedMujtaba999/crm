class ServiceCatalogItem {
  final String id;
  final String name;
  final String description;

  ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString() ?? '',
    );
  }
}
