class FilterInput {
  final String? startDate;
  final String? endDate;
  final String? category;
  final String? sortBy;
  final String? sortOrder;

  FilterInput({
    this.startDate,
    this.endDate,
    this.category,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (category != null) 'category': category,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  FilterInput copyWith({
    String? startDate,
    String? endDate,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) {
    return FilterInput(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
