import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/places_config.dart';
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

  /// Free-text address autocomplete.
  ///
  /// Order of preference:
  /// 1. Google Places API (New) — when the key is configured and the project
  ///    has billing + the API enabled.
  /// 2. Photon (OpenStreetMap) — keyless, CORS-enabled fallback so search keeps
  ///    working even if Google is unavailable/unbilled.
  /// 3. Built-in Texas list — last-resort fallback if both network calls fail.
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.trim().length < 2) return [];

    if (PlacesConfig.isConfigured) {
      final google = await _searchGoogle(query);
      if (google.isNotEmpty) return google;
    }

    final photon = await _searchPhoton(query);
    if (photon.isNotEmpty) return photon;

    return _mockAddressService.searchAddresses(query);
  }

  /// Google Places API (New) autocomplete. Supports browser CORS with an
  /// HTTP-referrer-restricted key. Returns [] on any error so the caller can
  /// fall back to Photon.
  Future<List<AddressSuggestion>> _searchGoogle(String query) async {
    try {
      final url = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': PlacesConfig.apiKey,
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': ['us'],
        }),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      final results = <AddressSuggestion>[];
      for (final suggestion in suggestions) {
        final prediction = (suggestion as Map<String, dynamic>)['placePrediction']
            as Map<String, dynamic>?;
        if (prediction == null) continue;

        final fullText =
            (prediction['text'] as Map<String, dynamic>?)?['text'] as String? ??
                '';
        final structured =
            prediction['structuredFormat'] as Map<String, dynamic>?;
        final mainText =
            (structured?['mainText'] as Map<String, dynamic>?)?['text']
                as String?;
        final secondaryText =
            (structured?['secondaryText'] as Map<String, dynamic>?)?['text']
                as String?;

        final street = mainText ?? fullText.split(',').first.trim();
        final secondaryParts = (secondaryText ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final city = secondaryParts.isNotEmpty ? secondaryParts[0] : '';
        final stateZip = secondaryParts.length > 1 ? secondaryParts[1] : '';
        final stateParts = stateZip.split(' ');
        final state = stateParts.isNotEmpty && stateParts[0].isNotEmpty
            ? stateParts[0]
            : 'TX';
        final zip = stateParts.length > 1 ? stateParts[1] : '';

        results.add(AddressSuggestion(
          fullAddress: fullText.isNotEmpty
              ? fullText
              : [street, city, '$state $zip'.trim()]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
          street: street,
          city: city,
          state: state,
          zip: zip,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Photon (OpenStreetMap) autocomplete — keyless and CORS-enabled, so it
  /// works directly from the web app with no API key, billing, or Google Cloud
  /// setup. Returns [] on any error.
  Future<List<AddressSuggestion>> _searchPhoton(String query) async {
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
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      final results = <AddressSuggestion>[];
      final seen = <String>{};
      for (final feature in features) {
        final props = (feature as Map<String, dynamic>)['properties']
            as Map<String, dynamic>?;
        if (props == null) continue;

        // Only surface US results for this Texas-focused rideshare.
        final countryCode = (props['countrycode'] as String?)?.toUpperCase();
        if (countryCode != null && countryCode != 'US') continue;

        final houseNumber = props['housenumber'] as String?;
        final road = props['street'] as String?;
        final name = props['name'] as String?;
        final city =
            (props['city'] ?? props['locality'] ?? props['county']) as String?;
        final stateRaw = props['state'] as String?;
        final state =
            stateRaw != null ? (_stateAbbr[stateRaw] ?? stateRaw) : '';
        final zip = props['postcode'] as String? ?? '';

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
      return results;
    } catch (_) {
      return [];
    }
  }

  String? getCityFromAddress(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    return parts.length > 1 ? parts[1] : null;
  }
}
