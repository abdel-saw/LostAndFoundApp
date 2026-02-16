
class Item {
  final int id;
  final String type;
  final String name;
  final String description;
  final String category;
  final String location;
  final String photoUrl;
  final String timestamp;
  final String userId;

  Item({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.photoUrl,
    required this.timestamp,
    required this.userId,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int,
      type: map['type'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      photoUrl: map['photo_url'] as String,
      timestamp: map['timestamp'] as String,
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'category': category,
      'location': location,
      'photo_url': photoUrl,
      'timestamp': timestamp,
      'user_id': userId,
    };
  }
}