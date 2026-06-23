/// Vehicle types and their seat capacity. This map is the single source of
/// truth for how many seats a route has, based on the vehicle serving it.
enum VehicleType {
  sedan,
  suv,
  minivan,
  pickup,
  van,
  sportsCar,
  luxurySedan,
}

extension VehicleTypeInfo on VehicleType {
  /// Seats available to riders for this vehicle type.
  int get seatCapacity {
    switch (this) {
      case VehicleType.sedan:
        return 3;
      case VehicleType.suv:
        return 5;
      case VehicleType.minivan:
        return 6;
      case VehicleType.pickup:
        return 4;
      case VehicleType.van:
        return 10;
      case VehicleType.sportsCar:
        return 1;
      case VehicleType.luxurySedan:
        return 3;
    }
  }

  /// Human-readable label for the UI.
  String get label {
    switch (this) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.minivan:
        return 'Minivan';
      case VehicleType.pickup:
        return 'Pickup';
      case VehicleType.van:
        return 'Van';
      case VehicleType.sportsCar:
        return 'Sports Car';
      case VehicleType.luxurySedan:
        return 'Luxury Sedan';
    }
  }
}
