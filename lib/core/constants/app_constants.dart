class AppConstants {
  AppConstants._();

  // Supabase table names
  static const String tableArtists = 'artists';
  static const String tableRecords = 'records';
  static const String tableGenres = 'genres';
  static const String tableDescriptors = 'descriptors';
  static const String tableRecordArtists = 'record_artists';
  static const String tableRecordGenres = 'record_genres';
  static const String tableRecordDescriptors = 'record_descriptors';
  static const String tableGenreHierarchy = 'genre_hierarchy';
  static const String tableDescriptorHierarchy = 'descriptor_hierarchy';
  static const String tableRecordStreaming = 'record_streaming';
  static const String tableAuditLog = 'audit_log';

  // Streaming services (display name -> DB value)
  static const List<String> streamingServices = [
    'Spotify',
    'Youtube',
    'SoundCloud',
    'Bandcamp',
    'SoulSeekQT (SSQT)',
  ];

  static const Map<String, String> streamingDbValues = {
    'SoulSeekQT (SSQT)': 'SoulSeekQT',
  };

  static String streamingToDb(String display) {
    return streamingDbValues[display] ?? display;
  }

  static String streamingToDisplay(String db) {
    for (final entry in streamingDbValues.entries) {
      if (entry.value == db) return entry.key;
    }
    return db;
  }

  // Default streaming service
  static const String defaultStreamingService = 'Spotify';

  // Record types (shared by Insert form, Search form, Edit popup)
  static const List<String> recordTypes = [
    'Album',
    'EP',
    'Mixtape',
    'Compilation',
    'Live',
    'Single',
    'Remix',
    'Deluxe',
  ];

  // Pagination
  static const int defaultPageSize = 50;

  // Search
  static const int searchDebounceMs = 300;
  static const int fuzzySearchMaxResults = 20;
}
