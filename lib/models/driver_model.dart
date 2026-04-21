class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> assignedRouteIds;
  final double totalPayout;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.assignedRouteIds,
    required this.totalPayout,
  });

  DriverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? assignedRouteIds,
    double? totalPayout,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      assignedRouteIds: assignedRouteIds ?? this.assignedRouteIds,
      totalPayout: totalPayout ?? this.totalPayout,
    );
  }
}
