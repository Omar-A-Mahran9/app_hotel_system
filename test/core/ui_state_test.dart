import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';

void main() {
  test('map dispatches to the matching branch', () {
    String describe(UiState<int> state) => state.map(
          initial: () => 'initial',
          loading: () => 'loading',
          success: (int data) => 'success:$data',
          empty: () => 'empty',
          failure: (Failure f) => 'failure:${f.kind.name}',
        );

    expect(describe(const UiState<int>.initial()), 'initial');
    expect(describe(const UiState<int>.loading()), 'loading');
    expect(describe(const UiState<int>.success(7)), 'success:7');
    expect(describe(const UiState<int>.empty()), 'empty');
    expect(
      describe(const UiState<int>.failure(Failure(FailureKind.server))),
      'failure:server',
    );
  });
}
