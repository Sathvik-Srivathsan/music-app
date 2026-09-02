class Record {
  final int? recordId;
  final String recordName;
  final String? recordType;
  final String? releaseDate;
  final int releaseDateMask;
  final String? dateAdded;
  final String? comments;
  final bool status;

  Record({
    this.recordId,
    required this.recordName,
    this.recordType,
    this.releaseDate,
    this.releaseDateMask = 7,
    this.dateAdded,
    this.comments,
    this.status = false,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      recordId: json['record_id'] as int?,
      recordName: json['record_name'] as String,
      recordType: json['record_type'] as String?,
      releaseDate: json['release_date'] as String?,
      releaseDateMask: json['release_date_mask'] as int? ?? 7,
      dateAdded: json['date_added'] as String?,
      comments: json['comments'] as String?,
      status: json['status'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (recordId != null) 'record_id': recordId,
      'record_name': recordName,
      'record_type': recordType,
      'release_date': releaseDate,
      'release_date_mask': releaseDateMask,
      'date_added': dateAdded,
      'comments': comments,
      'status': status,
    };
  }

  Record copyWith({
    int? recordId,
    String? recordName,
    String? recordType,
    String? releaseDate,
    int? releaseDateMask,
    String? dateAdded,
    String? comments,
    bool? status,
  }) {
    return Record(
      recordId: recordId ?? this.recordId,
      recordName: recordName ?? this.recordName,
      recordType: recordType ?? this.recordType,
      releaseDate: releaseDate ?? this.releaseDate,
      releaseDateMask: releaseDateMask ?? this.releaseDateMask,
      dateAdded: dateAdded ?? this.dateAdded,
      comments: comments ?? this.comments,
      status: status ?? this.status,
    );
  }

  String get displayStatus => status ? 'Finished' : 'Active';

  @override
  String toString() => recordName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Record &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          recordName == other.recordName;

  @override
  int get hashCode => recordId.hashCode ^ recordName.hashCode;
}
