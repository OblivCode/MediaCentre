import 'dart:convert';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../models/collection_block.dart';
import '../volume_provider.dart';

class DriveVolume implements VolumeProvider {
  static const String _fileName = 'remote_library.json';
  static const String _rootCollectionId = 'root';
  static const String _rootCollectionTitle = 'My Library';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  @override
  String get providerId => 'drive';

  @override
  String get providerName => 'Google Drive';

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  bool get requiresAuth => true;

  Future<http.Client?> _getAuthenticatedClient() async {
    if (_currentUser == null) return null;

    final headers = await _currentUser!.authHeaders;
    return _GoogleHttpClient(headers);
  }

  @override
  Future<bool> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      _currentUser = account;
      _httpClient = await _getAuthenticatedClient();
      if (_httpClient == null) {
        return false;
      }

      _driveApi = drive.DriveApi(_httpClient!);
      return true;
    } catch (e) {
      _currentUser = null;
      _driveApi = null;
      _httpClient = null;
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<String?> _findLibraryFileId() async {
    if (_driveApi == null) return null;

    try {
      final response = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name='$_fileName' and trashed=false",
        $fields: 'files(id, name)',
      );

      final files = response.files;
      if (files != null && files.isNotEmpty) {
        return files.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CollectionBlock> loadLibrary() async {
    if (_driveApi == null) {
      if (!await authenticate()) {
        return createEmptyLibrary();
      }
    }

    try {
      final fileId = await _findLibraryFileId();
      if (fileId == null) {
        return createEmptyLibrary();
      }

      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final content = await _readMediaStream(response);
      if (content.isEmpty) {
        return createEmptyLibrary();
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      return CollectionBlock.fromJson(json);
    } catch (e) {
      return createEmptyLibrary();
    }
  }

  Future<String> _readMediaStream(drive.Media media) async {
    final buffer = <int>[];
    await for (final chunk in media.stream) {
      buffer.addAll(chunk);
    }
    return utf8.decode(buffer);
  }

  @override
  Future<bool> saveLibrary(CollectionBlock library) async {
    if (_driveApi == null) {
      if (!await authenticate()) {
        return false;
      }
    }

    try {
      final json = jsonEncode(library.toJson());
      final content = utf8.encode(json);

      final existingFileId = await _findLibraryFileId();

      if (existingFileId != null) {
        final file = drive.File();
        await _driveApi!.files.update(
          file,
          existingFileId,
          uploadMedia: drive.Media(
            Stream.value(content),
            content.length,
          ),
        );
      } else {
        final file = drive.File()
          ..name = _fileName
          ..parents = ['appDataFolder'];

        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(
            Stream.value(content),
            content.length,
          ),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  CollectionBlock createEmptyLibrary() {
    return CollectionBlock(
      id: _rootCollectionId,
      title: _rootCollectionTitle,
      children: [],
    );
  }
}

class _GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
