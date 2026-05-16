/// Lightweight loading / success / error wrapper for repository → UI flows.
class DataState<T> {
  const DataState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.fromMock = false,
    this.fromCache = false,
  });

  const DataState.loading()
      : this(isLoading: true);

  const DataState.success(
    T value, {
    bool fromMock = false,
    bool fromCache = false,
  }) : this(
          data: value,
          fromMock: fromMock,
          fromCache: fromCache,
        );

  const DataState.failure(String message)
      : this(errorMessage: message);

  final T? data;
  final bool isLoading;
  final String? errorMessage;
  final bool fromMock;
  final bool fromCache;

  bool get hasData => data != null;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  DataState<T> copyWith({
    T? data,
    bool? isLoading,
    String? errorMessage,
    bool? fromMock,
    bool? fromCache,
  }) {
    return DataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      fromMock: fromMock ?? this.fromMock,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
