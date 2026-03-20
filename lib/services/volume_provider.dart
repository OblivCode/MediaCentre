import '../models/collection_block.dart';

abstract class VolumeProvider {
  String get providerId;
  String get providerName;
  bool get isAuthenticated;
  bool get requiresAuth;

  Future<bool> authenticate();
  Future<void> signOut();
  Future<CollectionBlock> loadLibrary();
  Future<bool> saveLibrary(CollectionBlock library);
  CollectionBlock createEmptyLibrary();
}
