import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_block.dart';
import '../models/media_block.dart';
import '../models/movie_block.dart';
import 'volume_provider.dart';
import 'volumes/local_volume.dart';
import 'volumes/drive_volume.dart';

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
