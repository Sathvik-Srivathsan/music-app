class Artist {
  final int? artistId;
  final String artistName;

  Artist({
    this.artistId,
    required this.artistName,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      artistId: json['artist_id'] as int?,
      artistName: json['artist_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (artistId != null) 'artist_id': artistId,
      'artist_name': artistName,
    };
  }

  Artist copyWith({int? artistId, String? artistName}) {
    return Artist(
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
    );
  }

  @override
  String toString() => artistName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist &&
          runtimeType == other.runtimeType &&
          artistId == other.artistId &&
          artistName == other.artistName;

  @override
  int get hashCode => artistId.hashCode ^ artistName.hashCode;
}
