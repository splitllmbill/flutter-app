import 'share_model.dart';

class ExpenseModel {
  final String? id;
  final String title;
  final double amount;
  final String? category;
  final String? paidBy;
  final String? paidByName;
  final List<ShareModel>? shares;
  final String? date;
  final String? eventId;
  final String? type;
  final String? description;
  final String? friendId;
  final bool? isSettled;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    this.category,
    this.paidBy,
    this.paidByName,
    this.shares,
    this.date,
    this.eventId,
    this.type,
    this.description,
    this.friendId,
    this.isSettled,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title'] ?? json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'],
      paidBy: json['paidBy'] ?? json['paid_by'],
      paidByName: json['paidByName'] ?? json['paid_by_name'],
      shares: json['shares'] != null
          ? (json['shares'] as List)
              .map((s) => ShareModel.fromJson(s))
              .toList()
          : null,
      date: json['date'],
      eventId: json['eventId'] ?? json['event_id'],
      type: json['type'],
      description: json['description'],
      friendId: json['friendId'] ?? json['friend_id'],
      isSettled: json['isSettled'] ?? json['is_settled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      if (category != null) 'category': category,
      if (paidBy != null) 'paidBy': paidBy,
      if (shares != null) 'shares': shares!.map((s) => s.toJson()).toList(),
      if (date != null) 'date': date,
      if (eventId != null) 'eventId': eventId,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (friendId != null) 'friendId': friendId,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? paidBy,
    String? paidByName,
    List<ShareModel>? shares,
    String? date,
    String? eventId,
    String? type,
    String? description,
    String? friendId,
    bool? isSettled,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      shares: shares ?? this.shares,
      date: date ?? this.date,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      description: description ?? this.description,
      friendId: friendId ?? this.friendId,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
