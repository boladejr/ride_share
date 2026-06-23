class AddressSuggestion {
  final String fullAddress;
  final String street;
  final String city;
  final String state;
  final String zip;

  AddressSuggestion({
    required this.fullAddress,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
  });
}

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  static const List<String> texasCities = [
    'Austin',
    'San Antonio',
    'Houston',
    'Dallas',
    'Fort Worth',
    'El Paso',
    'Waco',
    'Corpus Christi',
    'Lubbock',
    'Amarillo',
    'Laredo',
    'Plano',
    'Irving',
    'Arlington',
    'Frisco',
    'Round Rock',
    'McKinney',
    'Cedar Park',
    'Georgetown',
    'San Marcos',
    'New Braunfels',
    'Kyle',
    'Pflugerville',
    'Temple',
    'Killeen',
    'College Station',
    'Bryan',
    'Tyler',
    'Beaumont',
    'Midland',
    'Odessa',
  ];

  static final List<AddressSuggestion> _allAddresses = [
    // Austin
    AddressSuggestion(fullAddress: '1100 Congress Ave, Austin, TX 78701', street: '1100 Congress Ave', city: 'Austin', state: 'TX', zip: '78701'),
    AddressSuggestion(fullAddress: '800 Brazos St, Austin, TX 78701', street: '800 Brazos St', city: 'Austin', state: 'TX', zip: '78701'),
    AddressSuggestion(fullAddress: '600 Congress Ave, Austin, TX 78701', street: '600 Congress Ave', city: 'Austin', state: 'TX', zip: '78701'),
    AddressSuggestion(fullAddress: '1200 Barton Springs Rd, Austin, TX 78704', street: '1200 Barton Springs Rd', city: 'Austin', state: 'TX', zip: '78704'),
    AddressSuggestion(fullAddress: '2901 S Lamar Blvd, Austin, TX 78704', street: '2901 S Lamar Blvd', city: 'Austin', state: 'TX', zip: '78704'),
    AddressSuggestion(fullAddress: '4001 N Lamar Blvd, Austin, TX 78756', street: '4001 N Lamar Blvd', city: 'Austin', state: 'TX', zip: '78756'),
    AddressSuggestion(fullAddress: '6500 N Lamar Blvd, Austin, TX 78752', street: '6500 N Lamar Blvd', city: 'Austin', state: 'TX', zip: '78752'),
    AddressSuggestion(fullAddress: '9500 S IH 35, Austin, TX 78748', street: '9500 S IH 35', city: 'Austin', state: 'TX', zip: '78748'),
    AddressSuggestion(fullAddress: '1 University Station, Austin, TX 78712', street: '1 University Station', city: 'Austin', state: 'TX', zip: '78712'),
    AddressSuggestion(fullAddress: '3001 S Congress Ave, Austin, TX 78704', street: '3001 S Congress Ave', city: 'Austin', state: 'TX', zip: '78704'),
    AddressSuggestion(fullAddress: '11410 Century Oaks Ter, Austin, TX 78758', street: '11410 Century Oaks Ter', city: 'Austin', state: 'TX', zip: '78758'),
    AddressSuggestion(fullAddress: '2100 E Riverside Dr, Austin, TX 78741', street: '2100 E Riverside Dr', city: 'Austin', state: 'TX', zip: '78741'),
    // San Antonio
    AddressSuggestion(fullAddress: '300 Alamo Plaza, San Antonio, TX 78205', street: '300 Alamo Plaza', city: 'San Antonio', state: 'TX', zip: '78205'),
    AddressSuggestion(fullAddress: '100 E Houston St, San Antonio, TX 78205', street: '100 E Houston St', city: 'San Antonio', state: 'TX', zip: '78205'),
    AddressSuggestion(fullAddress: '849 E Commerce St, San Antonio, TX 78205', street: '849 E Commerce St', city: 'San Antonio', state: 'TX', zip: '78205'),
    AddressSuggestion(fullAddress: '5800 N Loop 1604 W, San Antonio, TX 78249', street: '5800 N Loop 1604 W', city: 'San Antonio', state: 'TX', zip: '78249'),
    AddressSuggestion(fullAddress: '15900 La Cantera Pkwy, San Antonio, TX 78256', street: '15900 La Cantera Pkwy', city: 'San Antonio', state: 'TX', zip: '78256'),
    AddressSuggestion(fullAddress: '1 AT&T Center Pkwy, San Antonio, TX 78219', street: '1 AT&T Center Pkwy', city: 'San Antonio', state: 'TX', zip: '78219'),
    // Houston
    AddressSuggestion(fullAddress: '1001 Avenida de las Americas, Houston, TX 77010', street: '1001 Avenida de las Americas', city: 'Houston', state: 'TX', zip: '77010'),
    AddressSuggestion(fullAddress: '500 Crawford St, Houston, TX 77002', street: '500 Crawford St', city: 'Houston', state: 'TX', zip: '77002'),
    AddressSuggestion(fullAddress: '5015 Westheimer Rd, Houston, TX 77056', street: '5015 Westheimer Rd', city: 'Houston', state: 'TX', zip: '77056'),
    AddressSuggestion(fullAddress: '6560 Fannin St, Houston, TX 77030', street: '6560 Fannin St', city: 'Houston', state: 'TX', zip: '77030'),
    AddressSuggestion(fullAddress: '2800 S Main St, Houston, TX 77098', street: '2800 S Main St', city: 'Houston', state: 'TX', zip: '77098'),
    AddressSuggestion(fullAddress: '1500 Hermann Dr, Houston, TX 77004', street: '1500 Hermann Dr', city: 'Houston', state: 'TX', zip: '77004'),
    // Dallas
    AddressSuggestion(fullAddress: '1717 N Harwood St, Dallas, TX 75201', street: '1717 N Harwood St', city: 'Dallas', state: 'TX', zip: '75201'),
    AddressSuggestion(fullAddress: '2323 Ross Ave, Dallas, TX 75201', street: '2323 Ross Ave', city: 'Dallas', state: 'TX', zip: '75201'),
    AddressSuggestion(fullAddress: '8687 N Central Expy, Dallas, TX 75225', street: '8687 N Central Expy', city: 'Dallas', state: 'TX', zip: '75225'),
    AddressSuggestion(fullAddress: '400 S Houston St, Dallas, TX 75202', street: '400 S Houston St', city: 'Dallas', state: 'TX', zip: '75202'),
    AddressSuggestion(fullAddress: '13350 Dallas Pkwy, Dallas, TX 75240', street: '13350 Dallas Pkwy', city: 'Dallas', state: 'TX', zip: '75240'),
    // Waco
    AddressSuggestion(fullAddress: '1300 S University Parks Dr, Waco, TX 76706', street: '1300 S University Parks Dr', city: 'Waco', state: 'TX', zip: '76706'),
    AddressSuggestion(fullAddress: '100 N Jack Kultgen Expy, Waco, TX 76702', street: '100 N Jack Kultgen Expy', city: 'Waco', state: 'TX', zip: '76702'),
    // El Paso
    AddressSuggestion(fullAddress: '500 W San Antonio Ave, El Paso, TX 79901', street: '500 W San Antonio Ave', city: 'El Paso', state: 'TX', zip: '79901'),
    AddressSuggestion(fullAddress: '4050 Rio Bravo Dr, El Paso, TX 79902', street: '4050 Rio Bravo Dr', city: 'El Paso', state: 'TX', zip: '79902'),
    // Round Rock
    AddressSuggestion(fullAddress: '4401 N IH 35, Round Rock, TX 78681', street: '4401 N IH 35', city: 'Round Rock', state: 'TX', zip: '78681'),
    AddressSuggestion(fullAddress: '2800 N Main Ave, Round Rock, TX 78665', street: '2800 N Main Ave', city: 'Round Rock', state: 'TX', zip: '78665'),
    // San Marcos
    AddressSuggestion(fullAddress: '601 University Dr, San Marcos, TX 78666', street: '601 University Dr', city: 'San Marcos', state: 'TX', zip: '78666'),
    // Georgetown
    AddressSuggestion(fullAddress: '1 College St, Georgetown, TX 78626', street: '1 College St', city: 'Georgetown', state: 'TX', zip: '78626'),
    // Fort Worth
    AddressSuggestion(fullAddress: '500 Commerce St, Fort Worth, TX 76102', street: '500 Commerce St', city: 'Fort Worth', state: 'TX', zip: '76102'),
    AddressSuggestion(fullAddress: '3401 W Lancaster Ave, Fort Worth, TX 76107', street: '3401 W Lancaster Ave', city: 'Fort Worth', state: 'TX', zip: '76107'),
  ];

  List<AddressSuggestion> searchAddresses(String query) {
    if (query.length < 2) return [];
    final lower = query.toLowerCase();
    return _allAddresses
        .where((a) =>
            a.fullAddress.toLowerCase().contains(lower) ||
            a.street.toLowerCase().contains(lower) ||
            a.city.toLowerCase().contains(lower))
        .take(8)
        .toList();
  }

  String getCityFromAddress(String fullAddress) {
    final match = _allAddresses
        .where((a) => a.fullAddress == fullAddress)
        .toList();
    if (match.isNotEmpty) return match.first.city;

    for (final city in texasCities) {
      if (fullAddress.contains(city)) return city;
    }
    return '';
  }
}
