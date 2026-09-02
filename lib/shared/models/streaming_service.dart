class StreamingService {
  final int? recordId;
  final String serviceName;
  final String serviceUrl;

  StreamingService({
    this.recordId,
    required this.serviceName,
    required this.serviceUrl,
  });

  factory StreamingService.fromJson(Map<String, dynamic> json) {
    return StreamingService(
      recordId: json['record_id'] as int?,
      // Legacy rows (pre-URL-field) carry SQL NULLs; degrade to ''.
      serviceName: (json['service_name'] ?? '') as String,
      serviceUrl: (json['service_url'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (recordId != null) 'record_id': recordId,
      'service_name': serviceName,
      'service_url': serviceUrl,
    };
  }

  StreamingService copyWith({int? recordId, String? serviceName, String? serviceUrl}) {
    return StreamingService(
      recordId: recordId ?? this.recordId,
      serviceName: serviceName ?? this.serviceName,
      serviceUrl: serviceUrl ?? this.serviceUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamingService &&
          runtimeType == other.runtimeType &&
          serviceName == other.serviceName &&
          serviceUrl == other.serviceUrl;

  @override
  int get hashCode => serviceName.hashCode ^ serviceUrl.hashCode;
}
