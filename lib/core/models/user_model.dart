class UserModel {
  final String? id;
  final String email;
  final String? name;
  final String? password;
  final String? friendCode;
  final String? upiId;

  UserModel({
    this.id,
    required this.email,
    this.name,
    this.password,
    this.friendCode,
    this.upiId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      friendCode: json['friendCode'] ?? json['friend_code'],
      upiId: json['upiId'] ?? json['upi_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (password != null) 'password': password,
      if (friendCode != null) 'friendCode': friendCode,
      if (upiId != null) 'upiId': upiId,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? password,
    String? friendCode,
    String? upiId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      friendCode: friendCode ?? this.friendCode,
      upiId: upiId ?? this.upiId,
    );
  }
}
