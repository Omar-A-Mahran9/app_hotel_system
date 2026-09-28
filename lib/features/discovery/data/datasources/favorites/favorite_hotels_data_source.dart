import '../../../../../core/data/data_source.dart';
import '../../../../../core/network/api_client.dart';

/// The signed-in guest's saved hotels (the Hotel Detail heart).
abstract interface class FavoriteHotelsDataSource {
  Future<Set<String>> fetchIds();

  Future<void> add(String hotelId);

  Future<void> remove(String hotelId);
}

/// `auth:guest` — `GET /guest/favorites/hotels`,
/// `PUT|DELETE /guest/favorites/hotels/{hotel}` (idempotent).
class ApiFavoriteHotelsDataSource implements FavoriteHotelsDataSource, RemoteDataSource {
  ApiFavoriteHotelsDataSource(this._client);

  final ApiClient _client;

  @override
  Future<Set<String>> fetchIds() async {
    final Map<String, dynamic> json = await _client.getJson('/guest/favorites/hotels');
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return <String>{
      for (final Object? row in rows)
        if (row is Map<String, Object?> && row['hotel_id'] != null) '${row['hotel_id']}',
    };
  }

  @override
  Future<void> add(String hotelId) => _client.putJson('/guest/favorites/hotels/$hotelId');

  @override
  Future<void> remove(String hotelId) => _client.deleteJson('/guest/favorites/hotels/$hotelId');
}

/// Offline/demo favourites kept for the session.
class DummyFavoriteHotelsDataSource implements FavoriteHotelsDataSource, DummyDataSource {
  final Set<String> _ids = <String>{};

  @override
  Future<Set<String>> fetchIds() async => Set<String>.of(_ids);

  @override
  Future<void> add(String hotelId) async => _ids.add(hotelId);

  @override
  Future<void> remove(String hotelId) async => _ids.remove(hotelId);
}
