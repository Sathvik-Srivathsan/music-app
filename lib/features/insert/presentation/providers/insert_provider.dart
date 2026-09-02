import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/core/utils/toast_utils.dart';
import 'package:music_collection/features/insert/data/repositories/insert_repository.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/core/logging/audit_outbox.dart';
import 'package:music_collection/core/logging/record_audit_logger.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';
import 'package:music_collection/shared/utils/record_tuple_log.dart';

/// Pure validation shared by Preview/Submit. Returns the error message
/// or null when the form may proceed. Mandatory per schema + app
/// policy: record name (DB NOT NULL) and at least one artist.
/// Record Type / Status always carry a value via their UI defaults,
/// so they need no check here.
String? validateInsertInput({
  required String recordName,
  required int artistCount,
}) {
  if (recordName.trim().isEmpty) return 'Record name is required';
  if (artistCount == 0) return 'At least one artist is required';
  return null;
}

class InsertProvider extends ChangeNotifier {
  final InsertRepository _repo = InsertRepository();

  // --- All entities loaded from DB ---
  List<Artist> allArtists = [];
  List<Genre> allGenres = [];
  List<Descriptor> allDescriptors = [];

  // --- Selected entities ---
  List<Artist> selectedArtists = [];
  List<Genre> selectedGenres = [];
  List<Descriptor> selectedDescriptors = [];

  // --- Streaming ---
  Map<String, bool> streamingSelected = {};
  Map<String, TextEditingController> streamingUrlControllers = {};

  // --- Form fields ---
  String recordName = '';
  String recordType = 'Album';
  String? releaseDate;
  String comments = '';
  bool status = false; // false = Active

  // --- Loading ---
  bool isLoading = false;
  bool isSaving = false;

  InsertProvider() {
    for (var service in AppConstants.streamingServices) {
      streamingSelected[service] = false;
      streamingUrlControllers[service] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in streamingUrlControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Load all entities ---
  Future<void> loadEntities() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchAllArtists(),
        _repo.fetchAllGenres(),
        _repo.fetchAllDescriptors(),
      ]);
      allArtists = results[0] as List<Artist>;
      allGenres = results[1] as List<Genre>;
      allDescriptors = results[2] as List<Descriptor>;
    } catch (e) {
      ToastUtils.showError('Failed to load data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Fuzzy match helper ---
  double fuzzyMatch(String query, String target) {
    return CsvUtils.calculateSimilarity(query.toLowerCase(), target.toLowerCase());
  }

  // --- Artist operations ---
  void addArtist(Artist artist) {
    if (!selectedArtists.contains(artist)) {
      selectedArtists.add(artist);
      notifyListeners();
    }
  }

  void removeArtist(Artist artist) {
    selectedArtists.remove(artist);
    notifyListeners();
  }

  Future<Artist> createArtist(String name, {String originTab = 'insert'}) async {
    final artist = await _repo.createArtist(name, originTab: originTab);
    allArtists.add(artist);
    notifyListeners();
    ToastUtils.showSuccess('Artist "$name" created');
    return artist;
  }

  void setSelectedArtists(List<Artist> artists) {
    selectedArtists = List.from(artists);
    notifyListeners();
  }

  // --- Genre operations ---
  void addGenre(Genre genre) {
    if (!selectedGenres.contains(genre)) {
      selectedGenres.add(genre);
      notifyListeners();
    }
  }

  void removeGenre(Genre genre) {
    selectedGenres.remove(genre);
    notifyListeners();
  }

  void reorderGenres(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = selectedGenres.removeAt(oldIndex);
    selectedGenres.insert(newIndex, item);
    notifyListeners();
  }

  Future<Genre> createGenre(String name, {String originTab = 'insert'}) async {
    final genre = await _repo.createGenre(name, originTab: originTab);
    allGenres.add(genre);
    notifyListeners();
    ToastUtils.showSuccess('Genre "$name" created');
    return genre;
  }

  void setSelectedGenres(List<Genre> genres) {
    selectedGenres = List.from(genres);
    notifyListeners();
  }

  // --- Descriptor operations ---
  void addDescriptor(Descriptor descriptor) {
    if (!selectedDescriptors.contains(descriptor)) {
      selectedDescriptors.add(descriptor);
      notifyListeners();
    }
  }

  void removeDescriptor(Descriptor descriptor) {
    selectedDescriptors.remove(descriptor);
    notifyListeners();
  }

  Future<Descriptor> createDescriptor(String name,
      {String originTab = 'insert'}) async {
    final descriptor = await _repo.createDescriptor(name, originTab: originTab);
    allDescriptors.add(descriptor);
    notifyListeners();
    ToastUtils.showSuccess('Descriptor "$name" created');
    return descriptor;
  }

  void setSelectedDescriptors(List<Descriptor> descriptors) {
    selectedDescriptors = List.from(descriptors);
    notifyListeners();
  }

  // --- Form field setters ---
  void setStatus(bool value) {
    status = value;
    notifyListeners();
  }

  void setRecordType(String value) {
    recordType = value;
    notifyListeners();
  }

  void setReleaseDate(String? value) {
    releaseDate = value;
    notifyListeners();
  }

  void setRecordName(String value) {
    recordName = value;
    notifyListeners();
  }

  void setComments(String value) {
    comments = value;
    notifyListeners();
  }

  // --- Streaming ---
  void toggleStreaming(String service) {
    streamingSelected[service] = !(streamingSelected[service] ?? false);
    notifyListeners();
  }

  void autoTickSpotify() {
    streamingSelected['Spotify'] = true;
    notifyListeners();
  }

  List<StreamingService> _getStreamingServices() {
    final services = <StreamingService>[];
    for (final entry in streamingSelected.entries) {
      if (entry.value) {
        services.add(StreamingService(
          serviceName: AppConstants.streamingToDb(entry.key),
          serviceUrl: streamingUrlControllers[entry.key]?.text ?? '',
        ));
      }
    }
    return services;
  }

  // --- Preview data ---
  Map<String, dynamic> buildPreviewData() {
    return {
      'record_name': recordName,
      'artists': selectedArtists.map((a) => a.artistName).join(', '),
      'genres': selectedGenres.map((g) => g.genreName).join(' > '),
      'descriptors': selectedDescriptors.map((d) => d.descriptorName).join(', '),
      'record_type': recordType,
      'release_date': releaseDate ?? '(not set)',
      'comments': comments.isEmpty ? '(none)' : comments,
      'status': status ? 'Finished' : 'Active',
      'streaming': _getStreamingServices().map((s) {
        final display = AppConstants.streamingToDisplay(s.serviceName);
        if (s.serviceUrl.isNotEmpty) {
          return '$display: ${s.serviceUrl}';
        }
        return display;
      }).join(', '),
    };
  }

  // --- Submit ---
  Future<bool> submit() async {
    if (recordName.trim().isEmpty) {
      ToastUtils.showWarning('Record name is required');
      return false;
    }

    if (releaseDate != null && releaseDate!.trim().isNotEmpty) {
      final canonical = canonicalizeReleaseDate(releaseDate);
      if (canonical.iso == null) {
        ToastUtils.showError(
            'Invalid release date: "${releaseDate!.trim()}". Use DD-MM-YYYY, MM-YYYY, or YYYY.');
        return false;
      }
    }

    isSaving = true;
    notifyListeners();

    try {
      final record = await _repo.insertFullRecord(
        recordName: recordName.trim(),
        artists: selectedArtists,
        genres: selectedGenres,
        descriptors: selectedDescriptors,
        recordType: recordType,
        releaseDate: releaseDate,
        comments: comments.isEmpty ? null : comments,
        status: status,
        streamingServices: _getStreamingServices(),
      );
      // Log the full inserted tuple once per commit (client-side, so the DB
      // trigger doesn't flood link rows). Enqueue the intent to the durable
      // outbox first (carries the full tuple), then fire-and-forget the actual
      // log write stamped with the same op_id — if it ever fails or the app
      // dies, the next launch flush() re-issues it (deduped by op_id).
      final recordDetails = RecordDetails(
        record: record,
        artists: List.of(selectedArtists),
        genres: List.of(selectedGenres),
        descriptors: List.of(selectedDescriptors),
        streaming: _getStreamingServices(),
      );
      final opId = await AuditOutbox.shared.enqueue(
        action: 'insert',
        details: RecordTupleLog.insertDetails(recordDetails),
        recordId: record.recordId,
        originTab: 'insert',
      );
      unawaited(RecordAuditLogger.logRecordAction(
        action: 'insert',
        details: recordDetails,
        originTab: 'insert',
        opId: opId,
      ));
      ToastUtils.showSuccess('Record "$recordName" added!');
      clearForm();
      return true;
    } catch (e) {
      ToastUtils.showError('Failed to save: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // --- Clear ---
  void clearForm() {
    recordName = '';
    recordType = 'Album';
    releaseDate = null;
    comments = '';
    status = false;
    selectedArtists = [];
    selectedGenres = [];
    selectedDescriptors = [];
    for (final key in streamingSelected.keys) {
      streamingSelected[key] = false;
    }
    for (final c in streamingUrlControllers.values) {
      c.clear();
    }
    notifyListeners();
  }
}
