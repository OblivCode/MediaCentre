import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/collection_block.dart';

class StorageService {
  static const String _fileName = 'local_library.json';
  static const String _rootCollectionId = 'root';
  static const String _rootCollectionTitle = 'My Library';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<CollectionBlock> loadLibrary() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return _createEmptyLibrary();
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return _createEmptyLibrary();
      }

      final json = jsonDecode(contents) as Map<String, dynamic>;
      return CollectionBlock.fromJson(json);
    } catch (e) {
      return _createEmptyLibrary();
    }
  }

  Future<void> saveLibrary(CollectionBlock library) async {
    final file = await _localFile;
    final json = jsonEncode(library.toJson());
    await file.writeAsString(json);
  }

  CollectionBlock _createEmptyLibrary() {
    return CollectionBlock(
      id: _rootCollectionId,
      title: _rootCollectionTitle,
      children: [],
    );
  }
}
