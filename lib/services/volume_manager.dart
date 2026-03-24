import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_block.dart';
import '../models/audio_blocks.dart';
import '../models/book_block.dart';
import '../models/comic_book_block.dart';
import '../models/media_block.dart';
import '../models/movie_block.dart';
import '../models/tv_show_block.dart';
import 'volume_provider.dart';
import 'volumes/local_volume.dart';
import 'volumes/drive_volume.dart';

class DuplicateMediaException implements Exception {
  final String message;
  DuplicateMediaException(this.message);

  @override
  String toString() => message;
}

class VolumeManager extends ChangeNotifier {
  static const String _volumePreferenceKey = 'selected_volume_id';

  final List<VolumeProvider> _availableVolumes = [];
  VolumeProvider? _activeVolume;
  CollectionBlock _library = CollectionBlock(id: 'root', title: 'My Library');
  bool _isLoading = false;
  String? _error;

  VolumeProvider? get activeVolume => _activeVolume;
  CollectionBlock get library => _library;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<VolumeProvider> get availableVolumes =>
      List.unmodifiable(_availableVolumes);

  VolumeManager() {
    _initializeVolumes();
  }

  void _initializeVolumes() {
    _availableVolumes.add(LocalVolume());
    _availableVolumes.add(DriveVolume());
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVolumeId = prefs.getString(_volumePreferenceKey);

    VolumeProvider? savedVolume;
    if (savedVolumeId != null) {
      savedVolume = _availableVolumes.firstWhere(
        (v) => v.providerId == savedVolumeId,
        orElse: () => _availableVolumes.first,
      );
    } else {
      savedVolume = _availableVolumes.first;
    }

    await setVolume(savedVolume);
  }

  Future<void> setVolume(VolumeProvider volume) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (volume.requiresAuth && !volume.isAuthenticated) {
        final authenticated = await volume.authenticate();
        if (!authenticated) {
          _error = 'Authentication failed';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _activeVolume = volume;
      _library = await volume.loadLibrary();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_volumePreferenceKey, volume.providerId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      _library = volume.createEmptyLibrary();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLibrary() async {
    if (_activeVolume == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _library = await _activeVolume!.loadLibrary();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMovie(MovieBlock movie) async {
    if (_activeVolume == null) return false;

    if (_checkForDuplicate(movie.tmdbId, 'movie')) {
      throw DuplicateMediaException('This movie is already in your library');
    }

    final updatedLibrary = _library.addChild(movie);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save movie';
      notifyListeners();
    }

    return success;
  }

  Future<bool> addCollection(CollectionBlock collection) async {
    if (_activeVolume == null) return false;

    final updatedLibrary = _library.addChild(collection);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save collection';
      notifyListeners();
    }

    return success;
  }

  Future<bool> addTvShow(TvShowBlock tvShow) async {
    if (_activeVolume == null) return false;

    if (_checkForDuplicate(tvShow.tmdbId, 'tv_show')) {
      throw DuplicateMediaException('This TV show is already in your library');
    }

    final updatedLibrary = _library.addChild(tvShow);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save TV show';
      notifyListeners();
    }

    return success;
  }

  Future<bool> addBook(BookBlock book) async {
    if (_activeVolume == null) return false;

    if (_checkForDuplicateBook(book.isbn)) {
      throw DuplicateMediaException('This book is already in your library');
    }

    final updatedLibrary = _library.addChild(book);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save book';
      notifyListeners();
    }

    return success;
  }

  Future<bool> addComicBook(ComicBookBlock comicBook) async {
    if (_activeVolume == null) return false;

    if (_checkForDuplicateComic(comicBook.anilistId)) {
      throw DuplicateMediaException('This comic is already in your library');
    }

    final updatedLibrary = _library.addChild(comicBook);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save comic book';
      notifyListeners();
    }

    return success;
  }

  Future<bool> deleteMovie(String id) async {
    if (_activeVolume == null) return false;

    final updatedLibrary = _library.removeChild(id);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to delete movie';
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateMovie(MovieBlock updatedMovie) async {
    if (_activeVolume == null) return false;

    final updatedChildren = _library.children.map((media) {
      if (media.id == updatedMovie.id) {
        return updatedMovie;
      }
      return media;
    }).toList();

    final updatedLibrary = _library.copyWith(children: updatedChildren);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to update movie';
      notifyListeners();
    }

    return success;
  }

  Future<bool> deleteMedia(String id) async {
    if (_activeVolume == null) return false;

    final updatedLibrary = _removeMediaById(_library, id);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to delete item';
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateMedia(MediaBlock updatedMedia) async {
    if (_activeVolume == null) return false;

    final updatedLibrary = _updateMediaById(_library, updatedMedia);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to update item';
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateBook(BookBlock updatedBook) async {
    return updateMedia(updatedBook);
  }

  Future<bool> updateComicBook(ComicBookBlock updatedComicBook) async {
    return updateMedia(updatedComicBook);
  }

  Future<bool> addAlbum(AlbumBlock album) async {
    if (_activeVolume == null) return false;

    if (_checkForDuplicateAlbum(album.lastFmMbid, album.title, album.artist)) {
      throw DuplicateMediaException('This album is already in your library');
    }

    final updatedLibrary = _library.addChild(album);
    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to save album';
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateAlbum(AlbumBlock updatedAlbum) async {
    return updateMedia(updatedAlbum);
  }

  CollectionBlock _removeMediaById(CollectionBlock parent, String id) {
    final updatedChildren = parent.children.where((m) => m.id != id).map((m) {
      if (m is CollectionBlock) {
        return _removeMediaById(m, id);
      }
      return m;
    }).toList();
    return parent.copyWith(children: updatedChildren);
  }

  CollectionBlock _updateMediaById(CollectionBlock parent, MediaBlock updated) {
    final updatedChildren = parent.children.map((m) {
      if (m.id == updated.id) {
        return updated;
      }
      if (m is CollectionBlock) {
        return _updateMediaById(m, updated);
      }
      return m;
    }).toList();
    return parent.copyWith(children: updatedChildren);
  }

  List<CollectionBlock> getAllCollections() {
    final collections = <CollectionBlock>[];
    _collectCollections(_library, collections);
    return collections;
  }

  List<MediaBlock> get watchableMedia {
    return _library.children
        .where((block) => block is MovieBlock || block is TvShowBlock)
        .toList();
  }

  List<MediaBlock> get readableMedia {
    return _library.children
        .where((block) => block is BookBlock || block is ComicBookBlock)
        .toList();
  }

  List<MediaBlock> get listableMedia {
    return _library.children.whereType<AlbumBlock>().toList();
  }

  List<CollectionBlock> get rootCollections {
    return _library.children.whereType<CollectionBlock>().toList();
  }

  CollectionBlock? getCollectionById(String id) {
    return _findCollectionById(_library, id);
  }

  void _collectCollections(
    CollectionBlock parent,
    List<CollectionBlock> collections,
  ) {
    for (final child in parent.children) {
      if (child is CollectionBlock) {
        collections.add(child);
        _collectCollections(child, collections);
      }
    }
  }

  CollectionBlock? _findCollectionById(CollectionBlock parent, String id) {
    for (final child in parent.children) {
      if (child is CollectionBlock) {
        if (child.id == id) return child;
        final found = _findCollectionById(child, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool _checkForDuplicate(int? tmdbId, String? type) {
    if (tmdbId == null) return false;
    return _findTmdbId(_library, tmdbId, type);
  }

  bool _checkForDuplicateBook(String? isbn) {
    if (isbn == null || isbn.isEmpty) return false;
    return _findBookDuplicate(_library, isbn);
  }

  bool _checkForDuplicateComic(int? anilistId) {
    if (anilistId == null) return false;
    return _findComicDuplicate(_library, anilistId);
  }

  bool _checkForDuplicateAlbum(String? mbid, String title, String? artist) {
    return _findAlbumDuplicate(_library, mbid, title, artist);
  }

  bool _findTmdbId(CollectionBlock parent, int tmdbId, String? type) {
    for (final child in parent.children) {
      if (child is MovieBlock && type == 'movie') {
        if (child.tmdbId == tmdbId) return true;
      } else if (child is TvShowBlock && type == 'tv_show') {
        if (child.tmdbId == tmdbId) return true;
      } else if (child is CollectionBlock) {
        if (_findTmdbId(child, tmdbId, type)) return true;
      }
    }
    return false;
  }

  bool _findBookDuplicate(CollectionBlock parent, String isbn) {
    for (final child in parent.children) {
      if (child is BookBlock && child.isbn != null && child.isbn == isbn) {
        return true;
      }
      if (child is CollectionBlock && _findBookDuplicate(child, isbn)) {
        return true;
      }
    }
    return false;
  }

  bool _findComicDuplicate(CollectionBlock parent, int anilistId) {
    for (final child in parent.children) {
      if (child is ComicBookBlock && child.anilistId == anilistId) {
        return true;
      }
      if (child is CollectionBlock && _findComicDuplicate(child, anilistId)) {
        return true;
      }
    }
    return false;
  }

  bool _findAlbumDuplicate(
    CollectionBlock parent,
    String? mbid,
    String title,
    String? artist,
  ) {
    final normalizedTitle = title.toLowerCase();
    final normalizedArtist = artist?.trim().toLowerCase();
    for (final child in parent.children) {
      if (child is AlbumBlock) {
        if (mbid != null && mbid.isNotEmpty && child.lastFmMbid == mbid) {
          return true;
        }
        final childArtist = child.artist?.trim().toLowerCase();
        if (child.title.toLowerCase() == normalizedTitle &&
            normalizedArtist != null &&
            normalizedArtist.isNotEmpty &&
            childArtist == normalizedArtist) {
          return true;
        }
      }
      if (child is CollectionBlock &&
          _findAlbumDuplicate(child, mbid, title, artist)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> moveMediaToCollection(String mediaId, String targetId) async {
    if (_activeVolume == null) return false;

    final media = _findMediaById(_library, mediaId);
    if (media == null) return false;

    var updatedLibrary = _removeMediaById(_library, mediaId);
    updatedLibrary = _addMediaToCollection(updatedLibrary, media, targetId);

    final success = await _activeVolume!.saveLibrary(updatedLibrary);

    if (success) {
      _library = updatedLibrary;
      notifyListeners();
    } else {
      _error = 'Failed to move item';
      notifyListeners();
    }

    return success;
  }

  MediaBlock? _findMediaById(CollectionBlock parent, String id) {
    for (final child in parent.children) {
      if (child.id == id) return child;
      if (child is CollectionBlock) {
        final found = _findMediaById(child, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  CollectionBlock _addMediaToCollection(
    CollectionBlock parent,
    MediaBlock media,
    String targetId,
  ) {
    if (parent.id == targetId) {
      return parent.addChild(media);
    }

    final updatedChildren = parent.children.map((m) {
      if (m is CollectionBlock) {
        return _addMediaToCollection(m, media, targetId);
      }
      return m;
    }).toList();
    return parent.copyWith(children: updatedChildren);
  }

  Future<bool> authenticateVolume(VolumeProvider volume) async {
    final success = await volume.authenticate();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<void> signOutVolume(VolumeProvider volume) async {
    await volume.signOut();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
