import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/presentation/base_view_model.dart';

/// Concrete implementation of BaseViewModel for testing
class TestViewModel extends BaseViewModel {
  int callCount = 0;

  Future<String> simulateAsyncOperation() async {
    callCount++;
    return 'Success';
  }

  Future<void> simulateAsyncError() async {
    await executeAsync(() async {
      throw Exception('Test error');
    });
  }
}

void main() {
  group('BaseViewModel', () {
    late TestViewModel viewModel;

    setUp(() {
      viewModel = TestViewModel();
    });

    tearDown(() {
      // Only dispose if not already disposed
      // Avoid "A TestViewModel was used after being disposed" error
      if (!viewModel.hasListeners) {
        // If it has no listeners, it means it's already been disposed or never had listeners
        return;
      }
      try {
        viewModel.dispose();
      } catch (e) {
        // Silently ignore if already disposed
      }
    });

    test('should initialize with default values', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
    });

    test('should set loading state correctly', () {
      viewModel.setLoading(true);
      expect(viewModel.isLoading, true);

      viewModel.setLoading(false);
      expect(viewModel.isLoading, false);
    });

    test('should not notify listeners if loading state does not change', () {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.setLoading(true);
      expect(notifyCount, 1);

      viewModel.setLoading(true); // Same state, should not notify
      expect(notifyCount, 1);

      viewModel.setLoading(false);
      expect(notifyCount, 2);
    });

    test('should set error message correctly', () {
      viewModel.setError('Test error message');
      expect(viewModel.errorMessage, 'Test error message');
      expect(viewModel.hasError, true);
    });

    test('should clear error message', () {
      viewModel.setError('Error');
      expect(viewModel.hasError, true);

      viewModel.clearError();
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
    });

    test('should handle executeAsync success path', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      final result = await viewModel.executeAsync(() async {
        return 'Test result';
      });

      expect(result, 'Test result');
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(notifyCount, greaterThanOrEqualTo(2)); // At least loading and complete
    });

    test('should set loading state during executeAsync', () async {
      final loadingStates = <bool>[];
      viewModel.addListener(() {
        loadingStates.add(viewModel.isLoading);
      });

      await viewModel.executeAsync(() async {
        return 'Result';
      });

      expect(loadingStates.contains(true), true); // Was loading at some point
      expect(viewModel.isLoading, false); // Finished loading
    });

    test('should handle executeAsync error path', () async {
      final result = await Future.wait(
        [
          viewModel.simulateAsyncError().catchError((_) {}),
        ],
        eagerError: true,
      ).catchError((_) => null);

      expect(viewModel.isLoading, false);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('should clear error before executing async operation', () async {
      viewModel.setError('Previous error');
      expect(viewModel.hasError, true);

      final result = await viewModel.executeAsync(() async {
        return 'Success';
      });

      expect(result, 'Success');
      expect(viewModel.hasError, false);
    });

    test('should rethrow exception from executeAsync', () async {
      expect(
        () async {
          await viewModel.executeAsync(() async {
            throw Exception('Test exception');
          });
        },
        throwsException,
      );
    });

    test('should notify listeners on error', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      try {
        await viewModel.executeAsync(() async {
          throw Exception('Error');
        });
      } catch (e) {
        // Expected
      }

      expect(notifyCount, greaterThanOrEqualTo(2)); // Loading and error states
      expect(viewModel.hasError, true);
    });

    test('should handle multiple consecutive executeAsync calls', () async {
      final result1 = await viewModel.executeAsync(() async => 'First');
      expect(result1, 'First');
      expect(viewModel.isLoading, false);

      final result2 = await viewModel.executeAsync(() async => 'Second');
      expect(result2, 'Second');
      expect(viewModel.isLoading, false);
    });

    test('should work with different return types', () async {
      final stringResult = await viewModel.executeAsync(() async => 'String');
      expect(stringResult, 'String');

      final intResult = await viewModel.executeAsync(() async => 42);
      expect(intResult, 42);

      final listResult = await viewModel.executeAsync(() async => [1, 2, 3]);
      expect(listResult, [1, 2, 3]);
    });

    test('should allow listeners to be removed', () {
      var notifyCount = 0;
      VoidCallback listener = () => notifyCount++;

      viewModel.addListener(listener);
      viewModel.setLoading(true);
      expect(notifyCount, 1);

      viewModel.removeListener(listener);
      viewModel.setLoading(false);
      expect(notifyCount, 1); // Should not have increased
    });

    test('should complete dispose without errors', () {
      // Create a new instance for this test to avoid interference with tearDown
      final testVM = TestViewModel();
      expect(() => testVM.dispose(), returnsNormally);
    });

    test('should handle null error message', () {
      viewModel.setError(null);
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
    });

    test('should track multiple error state changes', () {
      var errorChanges = <String?>[];
      
      viewModel.setError('Error 1');
      errorChanges.add(viewModel.errorMessage);

      viewModel.setError('Error 2');
      errorChanges.add(viewModel.errorMessage);

      viewModel.clearError();
      errorChanges.add(viewModel.errorMessage);

      expect(errorChanges, ['Error 1', 'Error 2', null]);
    });
  });
}
