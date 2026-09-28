import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_image_url_resolver.dart';

void main() {
  group('ApiImageUrlResolver', () {
    test('rewrites a localhost media URL onto the configured Android-emulator host', () {
      const resolver = ApiImageUrlResolver('http://10.0.2.2:8000');

      final result = resolver.resolve(
        'http://localhost:8000/storage/hotels/4/cover/abc.webp',
      );

      expect(result, 'http://10.0.2.2:8000/storage/hotels/4/cover/abc.webp');
    });

    test('rewrites a 127.0.0.1 media URL onto the configured host', () {
      const resolver = ApiImageUrlResolver('http://10.0.2.2:8000');

      final result = resolver.resolve('http://127.0.0.1:8000/storage/hotels/1/gallery/a.png');

      expect(result, 'http://10.0.2.2:8000/storage/hotels/1/gallery/a.png');
    });

    test('leaves a real CDN/production URL untouched', () {
      const resolver = ApiImageUrlResolver('http://10.0.2.2:8000');

      final result = resolver.resolve('https://cdn.example.com/oasis.jpg');

      expect(result, 'https://cdn.example.com/oasis.jpg');
    });

    test('leaves the URL untouched when it already matches the configured host', () {
      const resolver = ApiImageUrlResolver('http://10.0.2.2:8000');

      final result = resolver.resolve('http://10.0.2.2:8000/storage/hotels/4/cover/abc.webp');

      expect(result, 'http://10.0.2.2:8000/storage/hotels/4/cover/abc.webp');
    });

    test('passes null and empty input through unchanged — never fabricates a URL', () {
      const resolver = ApiImageUrlResolver('http://10.0.2.2:8000');

      expect(resolver.resolve(null), isNull);
      expect(resolver.resolve(''), '');
    });

    test('resolves onto localhost for Flutter Web / iOS Simulator style config', () {
      const resolver = ApiImageUrlResolver('http://localhost:8000');

      final result = resolver.resolve('http://127.0.0.1:8000/storage/hotels/4/cover/abc.webp');

      expect(result, 'http://localhost:8000/storage/hotels/4/cover/abc.webp');
    });

    test('a blank configured base URL never rewrites (safe no-op default)', () {
      const resolver = ApiImageUrlResolver('');

      final result = resolver.resolve('http://localhost:8000/storage/hotels/4/cover/abc.webp');

      expect(result, 'http://localhost:8000/storage/hotels/4/cover/abc.webp');
    });
  });
}
