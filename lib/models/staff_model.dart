import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_model.freezed.dart';
part 'staff_model.g.dart';

enum StaffRole {
  admin,
  cashier,
  waiter,
  kitchen;

  static StaffRole fromString(String value) =>
      StaffRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => StaffRole.waiter,
      );

  String get displayName => switch (this) {
    StaffRole.admin => 'Admin',
    StaffRole.cashier => 'Cashier',
    StaffRole.waiter => 'Waiter',
    StaffRole.kitchen => 'Kitchen',
  };
}

@freezed
class StaffModel with _$StaffModel {
  const factory StaffModel({
    required String id,
    required String name,
    required String email,
    required StaffRole role,
    @Default(true) bool isActive,
  }) = _StaffModel;

  factory StaffModel.fromJson(Map<String, dynamic> json) =>
      _$StaffModelFromJson(json);

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffModel.fromJson({...data, 'id': doc.id});
  }
}

extension StaffModelX on StaffModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}
