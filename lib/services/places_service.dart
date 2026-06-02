import 'dart:convert';
import 'package:http/http.dart' as http;
import 'address_service.dart';

class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  final AddressService _mockAddressService = AddressService();

  // US state name -> abbreviation (for clean display + city/state parsing).
  static const Map<String, String> _stateAbbr = {
    'Texas': 'TX',
    'Oklahoma': 'OK',
    'Louisiana': 'LA',
    'Arkansas': 'AR',
    'New Mexico': 'NM',
    'California': 'CA',
    'Florida': 'FL',
    'New York': 'NY',
  };

  /// Free-text address autocomplete via Photon (OpenStreetMap) — keyless and
  /// CORS-enabled, so it works directly from the web app with no API key,
  /// billing, or Google Cloud setup. Falls back to the built-in Texas list
  /// only if the network request fails.
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final url = Uri.https('photon.komoot.io', '/api/', {
        'q': query,
        'limit': '6',
        'lang': 'en',
        // Bias results toward central Texas (Austin) without hard-restricting.
        'lat': '30.2672',
        'lon': '-97.7431',
      });

      final response = await http.get(url);
      if (response.statusCode != 200) {
        return _mockAddressService.searchAddresses(query);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      final results = <AddressSuggestion>[];
      final seen = <String>{};
      for (final feature in features) {
        final props =
            (feature as Map<String, dynamic>)['properties'] as Map<String, dynamic>?;
        if (props == null) continue;

        // Only surface US results for this Texas-focused rideshare.
        final countryCode = (props['countrycode'] as String?)?.toUpperCase();
        if (countryCode != null && countryCode != 'US') continue;

        final houseNumber = props['housenumber'] as String?;
        final road = props['street'] as String?;
        final name = props['name'] as String?;
        final city = (props['city'] ?? props['locality'] ?? props['county'])
            as String?;
        final stateRaw = props['state'] as String?;
        final state = stateRaw != null
            ? (_stateAbbr[stateRaw] ?? stateRaw)
            : '';
        final zip = props['postcode'] as String? ?? '';

        // Build a clean street line: "1100 Congress Ave" or the POI name.
        String street;
        if (road != null && road.isNotEmpty) {
          street = houseNumber != null && houseNumber.isNotEmpty
              ? '$houseNumber $road'
              : road;
        } else {
          street = name ?? '';
        }
        if (street.isEmpty) continue;

        final cityPart = city ?? '';
        // fullAddress format keeps city at index 1 so getCityFromAddress works:
        // "<street>, <city>, <state> <zip>"
        final fullAddress = [
          street,
          cityPart,
          '$state $zip'.trim(),
        ].where((s) => s.isNotEmpty).join(', ');

        if (fullAddress.isEmpty || !seen.add(fullAddress)) continue;

        results.add(AddressSuggestion(
          fullAddress: fullAddress,
          street: street,
          city: cityPart,
          state: state.isNotEmpty ? state : 'TX',
          zip: zip,
        ));
      }

      // If Photon returned nothing useful, fall back to the built-in list.
      return results.isNotEmpty
          ? results
          : _mockAddressService.searchAddresses(query);
    } catch (_) {
      return _mockAddressService.searchAddresses(query);
    }
  }

  String? getCityFromAddress(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    return parts.length > 1 ? parts[1] : null;
  }
}
