class Genre {
  final int? genreId;
  final String genreName;

  Genre({
    this.genreId,
    required this.genreName,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      genreId: json['genre_id'] as int?,
      genreName: json['genre_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (genreId != null) 'genre_id': genreId,
      'genre_name': genreName,
    };
  }

  Genre copyWith({int? genreId, String? genreName}) {
    return Genre(
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
    );
  }

  @override
  String toString() => genreName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre &&
          runtimeType == other.runtimeType &&
          genreId == other.genreId &&
          genreName == other.genreName;

  @override
  int get hashCode => genreId.hashCode ^ genreName.hashCode;
}
