import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/app_content.dart';
import '../../domain/repositories/app_content_repository.dart';
import '../datasources/app_content_data_source.dart';

class AppContentRepositoryImpl implements AppContentRepository {
  AppContentRepositoryImpl(this._dataSource);

  final AppContentDataSource _dataSource;

  @override
  Future<AppContent> content() async {
    try {
      return await _dataSource.fetchContent();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
