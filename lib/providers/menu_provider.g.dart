// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(menuItemsStream)
const menuItemsStreamProvider = MenuItemsStreamProvider._();

final class MenuItemsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MenuItemModel>>,
          List<MenuItemModel>,
          Stream<List<MenuItemModel>>
        >
    with
        $FutureModifier<List<MenuItemModel>>,
        $StreamProvider<List<MenuItemModel>> {
  const MenuItemsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuItemsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuItemsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<MenuItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MenuItemModel>> create(Ref ref) {
    return menuItemsStream(ref);
  }
}

String _$menuItemsStreamHash() => r'61caf8d4b4db855f6c5806f3d09d9efa7eb5593f';

@ProviderFor(allMenuItemsStream)
const allMenuItemsStreamProvider = AllMenuItemsStreamProvider._();

final class AllMenuItemsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MenuItemModel>>,
          List<MenuItemModel>,
          Stream<List<MenuItemModel>>
        >
    with
        $FutureModifier<List<MenuItemModel>>,
        $StreamProvider<List<MenuItemModel>> {
  const AllMenuItemsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allMenuItemsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allMenuItemsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<MenuItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MenuItemModel>> create(Ref ref) {
    return allMenuItemsStream(ref);
  }
}

String _$allMenuItemsStreamHash() =>
    r'566d3c7dd3c0ba2785e81ed3cd29b33170760130';

@ProviderFor(menuItemsByCategory)
const menuItemsByCategoryProvider = MenuItemsByCategoryFamily._();

final class MenuItemsByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MenuItemModel>>,
          List<MenuItemModel>,
          Stream<List<MenuItemModel>>
        >
    with
        $FutureModifier<List<MenuItemModel>>,
        $StreamProvider<List<MenuItemModel>> {
  const MenuItemsByCategoryProvider._({
    required MenuItemsByCategoryFamily super.from,
    required MenuCategory super.argument,
  }) : super(
         retry: null,
         name: r'menuItemsByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$menuItemsByCategoryHash();

  @override
  String toString() {
    return r'menuItemsByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MenuItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MenuItemModel>> create(Ref ref) {
    final argument = this.argument as MenuCategory;
    return menuItemsByCategory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MenuItemsByCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$menuItemsByCategoryHash() =>
    r'5cda4c8b0ea1a5743e77d355f25cd74278335607';

final class MenuItemsByCategoryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MenuItemModel>>, MenuCategory> {
  const MenuItemsByCategoryFamily._()
    : super(
        retry: null,
        name: r'menuItemsByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MenuItemsByCategoryProvider call(MenuCategory category) =>
      MenuItemsByCategoryProvider._(argument: category, from: this);

  @override
  String toString() => r'menuItemsByCategoryProvider';
}

@ProviderFor(SelectedMenuCategory)
const selectedMenuCategoryProvider = SelectedMenuCategoryProvider._();

final class SelectedMenuCategoryProvider
    extends $NotifierProvider<SelectedMenuCategory, MenuCategory?> {
  const SelectedMenuCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMenuCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMenuCategoryHash();

  @$internal
  @override
  SelectedMenuCategory create() => SelectedMenuCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuCategory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuCategory?>(value),
    );
  }
}

String _$selectedMenuCategoryHash() =>
    r'95319cc27e2dbd86fc841603e1cb86c62e49e7de';

abstract class _$SelectedMenuCategory extends $Notifier<MenuCategory?> {
  MenuCategory? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MenuCategory?, MenuCategory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MenuCategory?, MenuCategory?>,
              MenuCategory?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(MenuSearchQuery)
const menuSearchQueryProvider = MenuSearchQueryProvider._();

final class MenuSearchQueryProvider
    extends $NotifierProvider<MenuSearchQuery, String> {
  const MenuSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuSearchQueryHash();

  @$internal
  @override
  MenuSearchQuery create() => MenuSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$menuSearchQueryHash() => r'8bfd14053bf22d6bdb3dfca7135ab4277629a106';

abstract class _$MenuSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredMenuItems)
const filteredMenuItemsProvider = FilteredMenuItemsProvider._();

final class FilteredMenuItemsProvider
    extends
        $FunctionalProvider<
          List<MenuItemModel>,
          List<MenuItemModel>,
          List<MenuItemModel>
        >
    with $Provider<List<MenuItemModel>> {
  const FilteredMenuItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredMenuItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredMenuItemsHash();

  @$internal
  @override
  $ProviderElement<List<MenuItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MenuItemModel> create(Ref ref) {
    return filteredMenuItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MenuItemModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MenuItemModel>>(value),
    );
  }
}

String _$filteredMenuItemsHash() => r'1075d6c4ffbc74fd2646f935aef80e98a5cf5f32';

@ProviderFor(groupedMenuItems)
const groupedMenuItemsProvider = GroupedMenuItemsProvider._();

final class GroupedMenuItemsProvider
    extends
        $FunctionalProvider<
          Map<MenuCategory, List<MenuItemModel>>,
          Map<MenuCategory, List<MenuItemModel>>,
          Map<MenuCategory, List<MenuItemModel>>
        >
    with $Provider<Map<MenuCategory, List<MenuItemModel>>> {
  const GroupedMenuItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupedMenuItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupedMenuItemsHash();

  @$internal
  @override
  $ProviderElement<Map<MenuCategory, List<MenuItemModel>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<MenuCategory, List<MenuItemModel>> create(Ref ref) {
    return groupedMenuItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<MenuCategory, List<MenuItemModel>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<MenuCategory, List<MenuItemModel>>>(value),
    );
  }
}

String _$groupedMenuItemsHash() => r'70f7cc0ff4d23d2b598a6f000dd6933f17f7bd14';

@ProviderFor(MenuNotifier)
const menuProvider = MenuNotifierProvider._();

final class MenuNotifierProvider
    extends $NotifierProvider<MenuNotifier, AsyncValue<void>> {
  const MenuNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuNotifierHash();

  @$internal
  @override
  MenuNotifier create() => MenuNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$menuNotifierHash() => r'80d232cf6244d1c441387730208ce025b7bb0760';

abstract class _$MenuNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
