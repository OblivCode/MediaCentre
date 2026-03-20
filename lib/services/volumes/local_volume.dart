import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/collection_block.dart';
import '../volume_provider.dart';

class LocalVolume implements VolumeProvider {
  static const String _fileName = 'local_library.json';
  static const String _rootCollectionId = 'root';
  static const String _rootCollectionTitle = 'My Library';

  @override
  String get providerId => 'local';

  @override
  String get providerName => 'Local Device';

  @override
  bool get isAuthenticated => true;

  @override
  bool get requiresAuth => false;

  @override
  Future<bool> authenticate() async => true;

  @override
  Future<void> signOut() async {}

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  @override
  Future<CollectionBlock> loadLibrary() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return createEmptyLibrary();
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return createEmptyLibrary();
      }

      final json = jsonDecode(contents) as Map<String, dynamic>;
      return CollectionBlock.fromJson(json);
    } catch (e) {
      return createEmptyLibrary();
    }
  }

  @override
  Future<bool> saveLibrary(CollectionBlock library) async {
    try {
      final file = await _localFile;
      final json = jsonEncode(library.toJson());
      await file.writeAsString(json);
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
