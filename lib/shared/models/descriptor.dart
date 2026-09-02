class Descriptor {
  final int? descriptorId;
  final String descriptorName;

  Descriptor({
    this.descriptorId,
    required this.descriptorName,
  });

  factory Descriptor.fromJson(Map<String, dynamic> json) {
    return Descriptor(
      descriptorId: json['descriptor_id'] as int?,
      descriptorName: json['descriptor_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (descriptorId != null) 'descriptor_id': descriptorId,
      'descriptor_name': descriptorName,
    };
  }

  Descriptor copyWith({int? descriptorId, String? descriptorName}) {
    return Descriptor(
      descriptorId: descriptorId ?? this.descriptorId,
      descriptorName: descriptorName ?? this.descriptorName,
    );
  }

  @override
  String toString() => descriptorName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Descriptor &&
          runtimeType == other.runtimeType &&
          descriptorId == other.descriptorId &&
          descriptorName == other.descriptorName;

  @override
  int get hashCode => descriptorId.hashCode ^ descriptorName.hashCode;
}
