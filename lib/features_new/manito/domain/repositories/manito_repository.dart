import 'package:manito/features_new/manito/domain/entities/manito_entity.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class ManitoRepository {
  Future<List<ManitoProposeEntity>> fetchProposeList();
  Future<ManitoProposeEntity> fetchProposeDetail(String proposeId, String languageCode);
  Future<void> acceptPropose(String proposeId, String selectedContentId);
  Future<List<Map<String, dynamic>>> fetchAcceptData([String languageCode = 'en']);
  Future<List<Map<String, dynamic>>> fetchGuessData();
  Future<ManitoPostEntity?> getManitoPost(String acceptId);
  Future<List<String>> uploadImages(List<AssetEntity> assets);
  Future<void> saveManitoPost(String acceptId, String description, List<AssetEntity> assets);
  Future<void> completeManitoPost(String acceptId, String description, List<AssetEntity> assets);
}
