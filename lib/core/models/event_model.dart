class EventModel {
  final String? id;
  final String title;
  final String? description;
  final List<String>? members;
  final String? createdBy;
  final String? createdAt;
  final double? totalExpense;

  EventModel({
    this.id,
    required this.title,
    this.description,
    this.members,
    this.createdBy,
    this.createdAt,
    this.totalExpense,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      members: json['members'] != null
          ? List<String>.from(json['members'])
          : null,
      createdBy: json['createdBy'] ?? json['created_by'],
      createdAt: json['createdAt'] ?? json['created_at'],
      totalExpense: (json['totalExpense'] ?? json['total_expense'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (members != null) 'members': members,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? members,
    String? createdBy,
    String? createdAt,
    double? totalExpense,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}
