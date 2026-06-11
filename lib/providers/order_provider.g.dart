// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ordersByTable)
const ordersByTableProvider = OrdersByTableFamily._();

final class OrdersByTableProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  const OrdersByTableProvider._({
    required OrdersByTableFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ordersByTableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ordersByTableHash();

  @override
  String toString() {
    return r'ordersByTableProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    final argument = this.argument as String;
    return ordersByTable(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersByTableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ordersByTableHash() => r'df35f136fc4440fec0c36e31b9f8e36dc3bb9a0b';

final class OrdersByTableFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<OrderModel>>, String> {
  const OrdersByTableFamily._()
    : super(
        retry: null,
        name: r'ordersByTableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrdersByTableProvider call(String tableId) =>
      OrdersByTableProvider._(argument: tableId, from: this);

  @override
  String toString() => r'ordersByTableProvider';
}

@ProviderFor(activeOrderForTable)
const activeOrderForTableProvider = ActiveOrderForTableFamily._();

final class ActiveOrderForTableProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderModel?>,
          OrderModel?,
          Stream<OrderModel?>
        >
    with $FutureModifier<OrderModel?>, $StreamProvider<OrderModel?> {
  const ActiveOrderForTableProvider._({
    required ActiveOrderForTableFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeOrderForTableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeOrderForTableHash();

  @override
  String toString() {
    return r'activeOrderForTableProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrderModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrderModel?> create(Ref ref) {
    final argument = this.argument as String;
    return activeOrderForTable(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveOrderForTableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeOrderForTableHash() =>
    r'cef0fa18840088b4ff6804025d25243ad2076053';

final class ActiveOrderForTableFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrderModel?>, String> {
  const ActiveOrderForTableFamily._()
    : super(
        retry: null,
        name: r'activeOrderForTableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveOrderForTableProvider call(String tableId) =>
      ActiveOrderForTableProvider._(argument: tableId, from: this);

  @override
  String toString() => r'activeOrderForTableProvider';
}

@ProviderFor(orderStream)
const orderStreamProvider = OrderStreamFamily._();

final class OrderStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderModel?>,
          OrderModel?,
          Stream<OrderModel?>
        >
    with $FutureModifier<OrderModel?>, $StreamProvider<OrderModel?> {
  const OrderStreamProvider._({
    required OrderStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderStreamHash();

  @override
  String toString() {
    return r'orderStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrderModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrderModel?> create(Ref ref) {
    final argument = this.argument as String;
    return orderStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderStreamHash() => r'97e56d0cbcb9dd3e631ae5745699211b1bbb344c';

final class OrderStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrderModel?>, String> {
  const OrderStreamFamily._()
    : super(
        retry: null,
        name: r'orderStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderStreamProvider call(String orderId) =>
      OrderStreamProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderStreamProvider';
}

@ProviderFor(activeOrdersStream)
const activeOrdersStreamProvider = ActiveOrdersStreamProvider._();

final class ActiveOrdersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  const ActiveOrdersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeOrdersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeOrdersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    return activeOrdersStream(ref);
  }
}

String _$activeOrdersStreamHash() =>
    r'66efb661713cacd14ef7d8c9feaa8de938b56e4e';

@ProviderFor(OrderDraft)
const orderDraftProvider = OrderDraftFamily._();

final class OrderDraftProvider
    extends
        $NotifierProvider<OrderDraft, ({List<OrderItem> items, String note})> {
  const OrderDraftProvider._({
    required OrderDraftFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDraftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDraftHash();

  @override
  String toString() {
    return r'orderDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderDraft create() => OrderDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({List<OrderItem> items, String note}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({List<OrderItem> items, String note})>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDraftHash() => r'd41b6eb43e23ff3330488a0dceb833af40a9d691';

final class OrderDraftFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderDraft,
          ({List<OrderItem> items, String note}),
          ({List<OrderItem> items, String note}),
          ({List<OrderItem> items, String note}),
          String
        > {
  const OrderDraftFamily._()
    : super(
        retry: null,
        name: r'orderDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDraftProvider call(String tableId) =>
      OrderDraftProvider._(argument: tableId, from: this);

  @override
  String toString() => r'orderDraftProvider';
}

abstract class _$OrderDraft
    extends $Notifier<({List<OrderItem> items, String note})> {
  late final _$args = ref.$arg as String;
  String get tableId => _$args;

  ({List<OrderItem> items, String note}) build(String tableId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<
              ({List<OrderItem> items, String note}),
              ({List<OrderItem> items, String note})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({List<OrderItem> items, String note}),
                ({List<OrderItem> items, String note})
              >,
              ({List<OrderItem> items, String note}),
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(OrderNotifier)
const orderProvider = OrderNotifierProvider._();

final class OrderNotifierProvider
    extends $NotifierProvider<OrderNotifier, AsyncValue<OrderModel?>> {
  const OrderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderNotifierHash();

  @$internal
  @override
  OrderNotifier create() => OrderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<OrderModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<OrderModel?>>(value),
    );
  }
}

String _$orderNotifierHash() => r'735d2eefeba0bf8cf771fa251693b62eee2d77c9';

abstract class _$OrderNotifier extends $Notifier<AsyncValue<OrderModel?>> {
  AsyncValue<OrderModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<OrderModel?>, AsyncValue<OrderModel?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrderModel?>, AsyncValue<OrderModel?>>,
              AsyncValue<OrderModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
