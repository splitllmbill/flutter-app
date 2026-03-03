class ShareModel {
  final String? userId;
  final String? userName;
  final double? amount;
  final double? percentage;

  ShareModel({
    this.userId,
    this.userName,
    this.amount,
    this.percentage,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      userName: json['userName'] ?? json['user_name'] ?? json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: json['percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (amount != null) 'amount': amount,
      if (percentage != null) 'percentage': percentage,
    };
  }

  ShareModel copyWith({
    String? userId,
    String? userName,
    double? amount,
    double? percentage,
  }) {
    return ShareModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}
